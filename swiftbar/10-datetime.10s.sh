#!/bin/bash
# SwiftBar clock plugin — day, date, time in the menu bar
# Refresh: every 10 seconds (filename suffix .10s.sh)

NOW=$(date "+%a %d %b %I:%M %p")

# Menu bar line
echo "$NOW"
