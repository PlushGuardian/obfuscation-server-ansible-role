#!/bin/bash
# Non‑interactive wrapper for 3x-ui install.sh
# Expects environment variables:
#   UI_PANEL_PORT   - panel port
#   UI_PANEL_ACME_PORT - ACME HTTP‑01 listener port

# The answers are fed in the exact order the installer expects them.
# Adjust the sequence if the installer's prompts change.
{
    echo "y"                                     # customize panel port
    echo "${UI_PANEL_PORT}"                      # panel port
    echo "2"                                     # choose IP option (default 2)
    echo ""                                      # skip IPv6 address
    echo "${UI_PANEL_ACME_PORT}"                 # ACME port
} | bash /tmp/install.sh



