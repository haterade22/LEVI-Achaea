"""Run the Lua test suite locally without installing Lua: lupa embeds Lua 5.1 (what Mudlet and CI run).

    python -m pip install lupa              # once (a virtualenv is fine)
    python tools/run_lua_tests.py           # the whole suite
    python tools/run_lua_tests.py src_new/tests/test_shikudo_tracking.lua   # one file

Exits with the runner's own status (0 = all passed). Added v4.7.414: until then CI was the first
place a test ever ran on this Windows machine, which has no lua5.1.

The runner (src_new/tests/test_runner.lua) finds test files with io.popen; with a file argument
that listing is replaced by the one file, so the mock, describe/it/expect and the summary behave
exactly as in a full run.
"""
import os
import sys

try:
    import lupa.lua51 as lupa
except ImportError:
    sys.exit("run_lua_tests: needs lupa (python -m pip install lupa)")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
lua = lupa.LuaRuntime(unpack_returned_tuples=True)
if len(sys.argv) > 1:
    lua.globals().ONLY_TEST_FILE = sys.argv[1].replace("\\", "/")
    lua.execute(r"""
      local real = io.popen
      io.popen = function(cmd, ...)
        if cmd:find("test_*.lua", 1, true) then
          local f = io.tmpfile(); f:write(ONLY_TEST_FILE .. "\n"); f:seek("set"); return f
        end
        return real(cmd, ...)
      end
    """)
lua.execute('dofile("src_new/tests/test_runner.lua")')   # the runner calls os.exit itself
