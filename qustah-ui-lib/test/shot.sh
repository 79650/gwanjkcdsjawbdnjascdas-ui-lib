#!/bin/bash
# Renders the example's pages from the mock into test/shots/*.png (needs the renderer in ../nova/tools).
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLS="${TOOLS:-/home/claude/nova/tools}"
"$HERE/run.sh" > /dev/null
"$TOOLS/shot.sh" "$HERE/example_bundled.lua" QustahUI_Qusth "$HERE/shots" dashboard overview:VisualsTab appearance:Appearance silent:SilentTab misc:MiscTab settings:SettingsTab profiles:Profiles info:SettingsTab,Info dropdown:MiscTab,VisualsTab,Appearance,Select
