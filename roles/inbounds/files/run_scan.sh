#!/bin/bash


# --- Configuration ---
# The path to the RealiTLScanner executable
SCANNER_DIR="/opt"
# The target to scan (e.g., an IP, CIDR range, or domain)
TARGET="31.44.2.82/24"
# The port to scan (usually 443 for HTTPS)
PORT=443
# Number of concurrent scanning threads
THREADS=100
# Timeout for each scan in seconds
TIMEOUT=5
# Output file for the raw scan results
RAW_OUTPUT="scan_results.csv"
# The final file to be used by Ansible
ANSIBLE_VARS_FILE="/home/ansible/reality_vars.yml"
# --- End of Configuration ---

# Function to detect public IP
detect_public_ip() {
    local ip=""
    for service in "https://api.ipify.org" "https://ifconfig.me/ip" "https://icanhazip.com" "https://checkip.amazonaws.com" "https://ipinfo.io/ip"; do
        ip=$(curl -s --max-time 5 "$service")
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    return 1
}

# Determine target
PUBLIC_IP=$(detect_public_ip)
if [ -z "$PUBLIC_IP" ]; then
    echo "[-] Failed to detect public IP. Please set TARGET manually."
    exit 1
fi
TARGET="${PUBLIC_IP%.*}.0/24"
echo "[+] Detected public IP: $PUBLIC_IP"
echo "[+] Scanning target CIDR range: $TARGET"

REALITY_SCANNER_VERSION="${REALITY_SCANNER_VERSION:-0.2.1}"  # Change to latest if needed

# ===========================================
#   HELPER FUNCTIONS
# ===========================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
error() { log "ERROR: $*" >&2; exit 1; }

# ===========================================
#   CREATE DIRECTORIES
# ===========================================
log "Creating scanner directory: $SCANNER_DIR"
sudo mkdir -p "$SCANNER_DIR"
sudo chmod 0755 "$SCANNER_DIR"

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
DEST_PATH="$SCANNER_DIR/RealiTLScanner"

log "Downloading RealiTLScanner v$REALITY_SCANNER_VERSION for $SCANNER_ARCH"
if ! sudo curl -L --fail --silent --show-error "$DOWNLOAD_URL" -o "$DEST_PATH"; then
    error "Failed to download binary from $DOWNLOAD_URL"
fi

sudo chmod 0755 "$DEST_PATH"
log "Binary saved to $DEST_PATH"
SCANNER_PATH="$DEST_PATH"


echo "[+] Starting RealiTLScanner on target: $TARGET"

# Check if the scanner exists
if [ ! -f "$SCANNER_PATH" ]; then
    echo "[-] Error: RealiTLScanner not found at $SCANNER_PATH"
    echo "[-] Please install it from: https://github.com/XTLS/RealiTLScanner"
    exit 1
fi

# Run the scanner
# The output is saved to a CSV file as per the tool's default behavior.
# We'll use the -out flag to ensure the filename.
$SCANNER_PATH -addr "$TARGET" -port "$PORT" -thread "$THREADS" -timeout "$TIMEOUT" -out "$RAW_OUTPUT"

# Check if the scan was successful and the output file was created
if [ ! -f "$RAW_OUTPUT" ]; then
    echo "[-] Error: Scan failed or output file '$RAW_OUTPUT' was not created."
    exit 1
fi

echo "[+] Scan completed. Analyzing results in $RAW_OUTPUT..."

# --- Parse the CSV to find the optimal candidate ---
# The CSV has headers: IP,ORIGIN,CERT_DOMAIN,CERT_ISSUER,GEO_CODE
# We'll look for the first entry that meets our criteria.
# For simplicity, we'll use the first valid entry after the header.

# Read the first data line, skipping the header
line=$(sed -n '2p' "$RAW_OUTPUT")
if [ -z "$line" ]; then
    echo "[-] No feasible destinations found in the scan results."
    exit 1
fi

# Extract the fields using awk (assuming comma-separated values)
dest_ip=$(echo "$line" | awk -F',' '{print $1}')
sni_domain=$(echo "$line" | awk -F',' '{print $3}')

# Validate the extracted data
if [ -z "$dest_ip" ] || [ -z "$sni_domain" ]; then
    echo "[-] Could not parse IP and SNI domain from the results."
    exit 1
fi

echo "[+] Optimal Destination: $dest_ip"
echo "[+] Optimal SNI: $sni_domain"

# Validate the extracted data
if [ -z "$dest_ip" ] || [ -z "$sni_domain" ]; then
    echo "[-] Could not parse IP and SNI domain from the results."
    exit 1
fi

echo "[+] Optimal Destination IP: $dest_ip"
echo "[+] Optimal SNI: $sni_domain"

# --- Determine the destination domain for the 'dest' field ---
# Perform a reverse DNS (PTR) lookup to get the domain associated with the IP.
# This is the recommended approach for the Reality 'dest' field.
dest_domain=$(dig +short -x "$dest_ip" | head -n 1 | sed 's/\.$//')

# If the PTR lookup fails, fall back to using the SNI domain from the certificate
if [ -z "$dest_domain" ]; then
    echo "[!] PTR record not found for $dest_ip. Falling back to using SNI domain for dest."
    dest_domain="$sni_domain"
fi

echo "[+] Destination Domain: $dest_domain"

# --- Create the Ansible variables file ---
echo "[+] Creating Ansible variables file: $ANSIBLE_VARS_FILE"
cat > "$ANSIBLE_VARS_FILE" << EOF
---
# Ansible variables for Reality configuration
reality_dest: "$dest_domain:$PORT"
reality_sni: "$sni_domain"
EOF

echo "[+] Done. Use the variables in '$ANSIBLE_VARS_FILE' for your Ansible playbooks."

Optional: Clean up the raw CSV file
rm "$RAW_OUTPUT"
