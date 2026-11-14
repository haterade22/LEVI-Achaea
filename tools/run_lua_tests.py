"""Run the Lua test suite locally without installing Lua: lupa embeds Lua 5.1 (what Mudlet and CI run).

    python -m pip install lupa              # once (a virtualenv is fine)
    python tools/run_lua_tests.py           # the whole suite
    python tools/run_lua_tests.py src_new/tests/test_shikudo_tracking.lua   # one file

Exits with the runner's own status (0 = all passed, 1 = a test failed, 2 = NOT RUN: no lupa here, or
the runner found no test file). Added v4.7.414: until then CI was the first place a test ever ran on
this Windows machine, which has no lua5.1.

The runner (src_new/tests/test_runner.lua) finds test files with io.popen; with a file argument
that listing is replaced by the one file, so the mock, describe/it/expect and the summary behave
exactly as in a full run.

io.popen: the lupa wheels for Linux and macOS build Lua 5.1 without it ("'popen' not supported"),
while the Windows wheel has it. Where it is missing, make_runtime() supplies one that runs the
command through the platform shell, so the suite runs the same way on every system.
"""
import os
import subprocess
import sys

try:
    import lupa.lua51 as lupa
except ImportError:
    lupa = None

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def shell_output(command):
    """What io.popen(command) would let Lua read: the command's standard output, as bytes.

    Lua's own popen reads in text mode, so a Windows row ends in "\\n" there; the same is done here.
    """
    done = subprocess.run(command, shell=True, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    return done.stdout.replace(b"\r\n", b"\n")


def make_runtime(force_shim=False):
    """A Lua 5.1 runtime whose io.popen works. force_shim: use the Python-backed one even where Lua has its own."""
    if lupa is None:
        # Exit 2 = NOT RUN: no test ran, so this is neither a pass nor a test failure (1).
        print("NOT RUN: run_lua_tests needs lupa with Lua 5.1, and %s has none (python -m pip install lupa, or use "
              "the interpreter that has it)" % sys.executable, file=sys.stderr)
        sys.exit(2)
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    native = lua.eval('function() local ok, h = pcall(io.popen, "echo") if ok and h then h:read("*a") h:close() return true end return false end')()
    if force_shim or not native:
        lua.eval("""function(run)
          io.popen = function(command)
            local f = io.tmpfile()
            f:write(run(command))
            f:seek("set")
            return f
          end
        end""")(shell_output)
    return lua


def main(argv):
    os.chdir(ROOT)
    lua = make_runtime()
    if len(argv) > 1:
        lua.globals().ONLY_TEST_FILE = argv[1].replace("\\", "/")
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


if __name__ == "__main__":
    main(sys.argv)
