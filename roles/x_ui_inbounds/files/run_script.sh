#!/usr/bin/env bash
set -euo pipefail

# ===========================================
#   CONFIGURATION (override via environment)
# ===========================================
REALITY_SCANNER_DIR="${REALITY_SCANNER_DIR:/opt}"
REALITY_SCANNER_OUTPUT_DIR="${REALITY_SCANNER_OUTPUT_DIR:-$REALITY_SCANNER_DIR/output}"
REALITY_SCANNER_VERSION="${REALITY_SCANNER_VERSION:-0.2.1}"  # Change to latest if needed

# ===========================================
#   HELPER FUNCTIONS
# ===========================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { log "ERROR: $*" >&2; exit 1; }

# ===========================================
#   CREATE DIRECTORIES
# ===========================================
log "Creating scanner directory: $REALITY_SCANNER_DIR"
sudo mkdir -p "$REALITY_SCANNER_DIR"
sudo chmod 0755 "$REALITY_SCANNER_DIR"

log "Creating output directory: $REALITY_SCANNER_OUTPUT_DIR"
sudo mkdir -p "$REALITY_SCANNER_OUTPUT_DIR"
sudo chmod 0755 "$REALITY_SCANNER_OUTPUT_DIR"

# ===========================================
#   DETECT ARCHITECTURE AND DOWNLOAD BINARY
# ===========================================
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)   SCANNER_ARCH="arm64" ;;
    x86_64|amd64)    SCANNER_ARCH="amd64" ;;
    *)               error "Unsupported architecture: $ARCH" ;;
esac

if [[ "$SCANNER_ARCH" == "arm64" ]]; then
    BINARY_NAME="RealiTLScanner-linux-arm64"
else
    BINARY_NAME="RealiTLScanner-linux-64"
fi

DOWNLOAD_URL="https://github.com/XTLS/RealiTLScanner/releases/download/v${REALITY_SCANNER_VERSION}/${BINARY_NAME}"
DEST_PATH="$REALITY_SCANNER_DIR/RealiTLScanner"

log "Downloading RealiTLScanner v$REALITY_SCANNER_VERSION for $SCANNER_ARCH"
if ! sudo curl -L --fail --silent --show-error "$DOWNLOAD_URL" -o "$DEST_PATH"; then
    error "Failed to download binary from $DOWNLOAD_URL"
fi

sudo chmod 0755 "$DEST_PATH"
log "Binary saved to $DEST_PATH"

# ===========================================
#   GET GEOLOCATION AND CHOOSE SNI
# ===========================================
log "Detecting public IP and country code..."
# Try multiple free geolocation services with fallback
COUNTRY_CODE=""
for api in "https://ipapi.co/country/" "https://ipinfo.io/country" "https://ifconfig.co/country"; do
    COUNTRY_CODE=$(curl -s --max-time 5 "$api" 2>/dev/null | tr -d '[:space:]')
    if [[ -n "$COUNTRY_CODE" && "$COUNTRY_CODE" =~ ^[A-Z]{2}$ ]]; then
        log "Country code detected: $COUNTRY_CODE (via $api)"
        break
    fi
done

if [[ -z "$COUNTRY_CODE" ]]; then
    log "Could not determine country code; falling back to default"
    COUNTRY_CODE="default"
fi

# Map country code to SNI
declare -A SNI_MAP=(
    [DE]="www.telekom.de"
    [NL]="www.nu.nl"
    [GB]="www.bbc.co.uk"
    [FI]="www.yle.fi"
    [US]="www.microsoft.com"
    [JP]="www.ntt.com"
    [RU]="www.yandex.ru"
    [default]="www.cloudflare.com"
)

SELECTED_SNI="${SNI_MAP[$COUNTRY_CODE]:-${SNI_MAP[default]}}"
log "Selected SNI: $SELECTED_SNI"

# ===========================================
#   RUN REALITLSCANNER
# ===========================================
HOSTNAME_SHORT=$(hostname -s)
OUTPUT_FILE="$REALITY_SCANNER_OUTPUT_DIR/${HOSTNAME_SHORT}_dest.csv"

# Avoid re‑running if output already exists
if [[ -f "$OUTPUT_FILE" ]]; then
    log "Output file $OUTPUT_FILE already exists. Skipping scan."
    exit 0
fi

log "Running RealiTLScanner against $SELECTED_SNI:443 ..."
# The binary might need root to bind to low ports? Unlikely. Run as current user.
"$DEST_PATH" -addr "$SELECTED_SNI" -port 443 -thread 10 -timeout 5 -out "$OUTPUT_FILE"

if [[ -f "$OUTPUT_FILE" ]]; then
    log "Scan completed. Results written to $OUTPUT_FILE"
else
    error "Scan did not produce output file"
fi
