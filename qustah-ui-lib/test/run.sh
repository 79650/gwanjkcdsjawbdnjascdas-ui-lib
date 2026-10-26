#!/bin/bash
# Builds the bundle, runs example.lua + test/lib_steps.lua in the Qustah mock (../nova/tools), prints the result.
# Screenshots: test/shot.sh
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$HERE/.."
TOOLS="${TOOLS:-/home/claude/nova/tools}"
python3 "$ROOT/build.py" || exit 1
BUNDLE="${BUNDLE:-$ROOT/dist/qustah-ui-lib.lua}"
{ echo 'local Lib = (function()'; cat "$BUNDLE"; echo 'end)()'; tail -n +3 "$ROOT/example.lua"; echo 'getgenv().TestLib = Lib'; } > "$HERE/example_bundled.lua"
"$TOOLS/smoke.sh" "$HERE/example_bundled.lua" "$HERE/lib_steps.lua" > "$HERE/last_run.txt" 2>&1
grep -E "^FAIL|LIB TESTS|thread error|attempt to|^== errors|unknown mock" -A2 "$HERE/last_run.txt" | grep -v "^--$" | head -60
