"""Tests for tools/check_context_budget.py.

    python -B tools/test_check_context_budget.py
"""
import os
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check_context_budget as cb  # noqa: E402


def said():
    rows = []
    return rows, rows.append


def tree(files):
    temp = tempfile.TemporaryDirectory()
    for rel, data in files.items():
        path = os.path.join(temp.name, *rel.split("/"))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(data)
    return temp


class Budget(unittest.TestCase):
    def config(self, ceiling, strict=False):
        return {"strict": strict, "headroom": 10, "files": {"CLAUDE.md": {"ceiling": ceiling, "target": 5}}}

    def test_size_counts_a_line_end_once(self):
        with tree({"a.md": b"one\r\ntwo\r\n", "b.md": b"one\ntwo\n"}) as root:
            self.assertEqual(cb.size_of(os.path.join(root, "a.md")), 8)
            self.assertEqual(cb.size_of(os.path.join(root, "b.md")), 8)

    def test_a_file_within_its_ceiling_passes(self):
        with tree({"CLAUDE.md": b"x" * 100}) as root:
            rows, out = said()
            self.assertEqual(cb.check_budget(self.config(100), root, out), 0)
            self.assertIn("OK", rows[0])

    def test_over_the_ceiling_is_report_only_until_strict(self):
        with tree({"CLAUDE.md": b"x" * 101}) as root:
            rows, out = said()
            self.assertEqual(cb.check_budget(self.config(100), root, out), 0)
            self.assertIn("OVER (report-only)", rows[0])
            self.assertIn("(+1)", rows[0])
            rows, out = said()
            self.assertEqual(cb.check_budget(self.config(100, strict=True), root, out), 1)
            self.assertIn("OVER --", rows[0])

    def test_a_missing_file_fails_even_when_report_only(self):
        with tree({"other.md": b"x"}) as root:
            rows, out = said()
            self.assertEqual(cb.check_budget(self.config(100), root, out), 1)
            self.assertIn("is missing", rows[0])

    def test_no_file_named_is_not_run(self):
        rows, out = said()
        self.assertEqual(cb.check_budget({"files": {}}, out=out), 2)
        self.assertIn("NOT RUN", rows[0])

    def test_lower_goes_down_and_never_up(self):
        with tree({"CLAUDE.md": b"x" * 50}) as root:
            config = self.config(100)
            self.assertTrue(cb.lower_ceilings(config, root, out=lambda row: None))
            self.assertEqual(config["files"]["CLAUDE.md"]["ceiling"], 60, "size 50 + headroom 10")
            self.assertFalse(cb.lower_ceilings(config, root, out=lambda row: None))
            config = self.config(40)        # the file is over a low ceiling: --lower must not rescue it
            self.assertFalse(cb.lower_ceilings(config, root, out=lambda row: None))
            self.assertEqual(config["files"]["CLAUDE.md"]["ceiling"], 40)

    def test_lower_stops_at_the_target(self):
        with tree({"CLAUDE.md": b"x" * 2}) as root:
            config = {"headroom": 1, "files": {"CLAUDE.md": {"ceiling": 100, "target": 30}}}
            cb.lower_ceilings(config, root, out=lambda row: None)
            self.assertEqual(config["files"]["CLAUDE.md"]["ceiling"], 30)

    def test_the_real_config_names_claude_md_and_passes_or_reports(self):
        import json
        with open(cb.CONFIG, encoding="utf-8") as fh:
            config = json.load(fh)
        self.assertIn("CLAUDE.md", config["files"])
        rows = cb.budget_rows(config)
        self.assertIsNotNone(rows[0][1], "CLAUDE.md exists")
        self.assertFalse(rows[0][3], "CLAUDE.md is over its ceiling: move the new detail to its one home (docs/adrs/002)")


BASE = """# Guide

## Rules

Keep this rule.

## Big System

The `big_system` module tracks runs.
It has a `run_start` handler.

```lua
big_system.start()
```

### Detail

More about `run_start`.

## Old History

v1.2.3 changed `gone_helper`.
v1.2.4 changed `kept_helper`.

## Tail

The end.
"""

NOW = """# Guide

## Rules

Keep this rule.

## Big System

Moved to `docs/big.md`.

## Tail

The end.
"""

HOME = """# Big System (moved from the guide)

The `big_system` module tracks runs.
It has a `run_start` handler.

```lua
big_system.start()
```

### Detail

More about `run_start`.
"""


class Moves(unittest.TestCase):
    def test_removed_rows_are_a_multiset_difference(self):
        gone = cb.removed_rows("a\nb\nb\n\nc\n", "a\nb\n")
        self.assertEqual(dict(gone), {"b": 1, "c": 1})

    def test_section_rows_stop_at_the_next_heading_of_the_same_level(self):
        block = cb.section_rows(BASE, "## Big System")
        self.assertEqual(block[0], "## Big System")
        self.assertIn("### Detail", block)
        self.assertIn("More about `run_start`.", block)
        self.assertNotIn("## Old History", block)
        self.assertIsNone(cb.section_rows(BASE, "## No Such Section"))

    def test_a_heading_inside_a_code_fence_does_not_end_a_section(self):
        text = "## A\n\n```\n## not a heading\n```\n\nstill A\n\n## B\n"
        self.assertIn("still A", cb.section_rows(text, "## A"))

    def test_a_verbatim_move_with_a_declared_deletion_passes(self):
        deleted = [cb.section_rows(BASE, "## Old History")]
        verdict = cb.judge_moves(BASE, NOW, set(cb.rows_of(HOME)), deleted, corpus="gone_helper kept_helper")
        self.assertEqual(verdict["lost"], [])
        self.assertEqual(verdict["missing_identifiers"], [])
        self.assertIn("It has a `run_start` handler.", verdict["moved"])
        self.assertIn("v1.2.3 changed `gone_helper`.", verdict["deleted"])

    def test_a_row_that_reached_no_home_is_lost(self):
        home = HOME.replace("It has a `run_start` handler.\n", "")
        deleted = [cb.section_rows(BASE, "## Old History")]
        verdict = cb.judge_moves(BASE, NOW, set(cb.rows_of(home)), deleted, corpus="gone_helper kept_helper")
        self.assertEqual(verdict["lost"], ["It has a `run_start` handler."])

    def test_a_reworded_row_is_lost(self):
        home = HOME.replace("tracks runs", "follows runs")
        verdict = cb.judge_moves(BASE, NOW, set(cb.rows_of(home)), [cb.section_rows(BASE, "## Old History")], corpus="gone_helper kept_helper")
        self.assertEqual(verdict["lost"], ["The `big_system` module tracks runs."])

    def test_an_undeclared_deletion_is_lost(self):
        verdict = cb.judge_moves(BASE, NOW, set(cb.rows_of(HOME)), [], corpus="gone_helper kept_helper")
        self.assertIn("v1.2.3 changed `gone_helper`.", verdict["lost"])

    def test_a_deleted_identifier_must_still_exist_somewhere(self):
        deleted = [cb.section_rows(BASE, "## Old History")]
        verdict = cb.judge_moves(BASE, NOW, set(cb.rows_of(HOME)), deleted, corpus="only kept_helper is here")
        self.assertEqual(verdict["lost"], [])
        self.assertEqual(verdict["missing_identifiers"], ["gone_helper"])

    def test_nothing_left_is_reported_as_zero(self):
        self.assertEqual(cb.judge_moves(BASE, BASE, set())["left"], 0)

    def test_moves_without_a_base_is_not_run(self):
        import contextlib
        import io
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(cb.main(["--moves"]), 2)
        self.assertIn("NOT RUN", out.getvalue())


if __name__ == "__main__":
    unittest.main(verbosity=1)
