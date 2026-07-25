#!/bin/bash
# Non‑interactive wrapper for mtproxymax-installer.sh

# The answers are fed in the exact order the installer expects them.
# Adjust the sequence if the installer's prompts change.
{
    echo "${MTPROXYMAX_MTPROXY_PORT}"               # MTProxy/MTProxyMax port
    echo ""                                         # MTProxyMax listen IP, takes the default
    echo "4"                                        # customise FakeTLS domain
    echo "${MTPROXYMAX_MTPROXY_FAKETLS_DOMAIN}"     # FakeTLS domain
    echo "y"                                        # Enable traffic masking
    echo "n"                                        # Ad-tag
    echo "${MTPROXYMAX_MTPROXY_CPU_LIMIT}"          # Resource limits: CPU
    echo "${MTPROXYMAX_MTPROXY_MEMORY_LIMIT}"       # Resource limits: memory
    echo ""                                         # Add default secret
    echo "n"                                        # Add Telegram bot, needs to be setup manually
    echo ""                                         # Go to main menu
    echo "0"                                        # Exit main menu
} | bash /tmp/mtproxymax-install.sh
