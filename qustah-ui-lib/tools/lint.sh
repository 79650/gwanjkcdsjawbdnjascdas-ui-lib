#!/bin/bash
# Lint: selene (bugs, unused / undefined names) and a StyLua formatting check when the tools are on PATH.
#   selene: https://github.com/Kampfkarren/selene/releases   stylua: https://github.com/JohnnyMorganz/StyLua/releases
cd "$(dirname "$0")/.." || exit 1
status=0
if command -v selene >/dev/null; then selene src || status=1; else echo "selene not found - skipped"; fi
if [ "$1" = "--format" ] && command -v stylua >/dev/null; then stylua --check src || status=1; fi
exit $status
