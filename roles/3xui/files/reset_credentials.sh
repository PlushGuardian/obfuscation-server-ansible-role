#!/usr/bin/env bash
# reset_credentials.sh – Reset 3x-UI Web UI credentials non‑interactively

set -euo pipefail

# Use environment variables if set, otherwise fallback to defaults
USERNAME="${UI_USERNAME:-admin}"
PASSWORD="${UI_PASSWORD:-youneedtosetapasswordactually}"

{
    echo "6"             # Please enter your selection
    echo "y"             # Are you sure to reset the username and password of the panel
    echo "${USERNAME}"   # Please set the login username
    echo "${PASSWORD}"   # Please set the login password
    echo "y"             # Do you want to disable currently configured two-factor authentication
    echo "y"             # Restart the panel, Attention: Restarting the panel will also restart xray
    echo ""              # Press enter to return to the main menu
} | x-ui
