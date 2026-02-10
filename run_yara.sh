#!/bin/bash

# MCP Scanner Script - YARA Analyzer Only
# Scans remote MCP server using YARA rules

# Activate virtual environment
source .venv/bin/activate

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Parse arguments - if first arg doesn't start with http://, treat it as filename
if [[ "$1" == http://* ]] || [[ "$1" == https://* ]]; then
    # First argument is a URL
    SERVER_URL="${1:-http://192.168.174.129:8000/sse}"
    FORMAT="${2:-detailed}"
    OUTPUT_FILENAME="${3:-scan_$(date +%Y%m%d_%H%M%S).txt}"
else
    # First argument is a filename (or empty)
    SERVER_URL="${SERVER_URL:-http://192.168.174.129:8000/sse}"
    FORMAT="${FORMAT:-detailed}"
    OUTPUT_FILENAME="${1:-scan_$(date +%Y%m%d_%H%M%S).txt}"
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"

# Full output file path
OUTPUT_FILE="$OUTPUT_DIR/$OUTPUT_FILENAME"

echo "=========================================="
echo "MCP Scanner - YARA Analyzer"
echo "=========================================="
echo "Server URL: $SERVER_URL"
echo "Format: $FORMAT"
echo "Output File: $OUTPUT_FILE"
echo "=========================================="
echo ""

# Run the scanner with YARA analyzer and save output to file
mcp-scanner \
    --server-url "$SERVER_URL" \
    --analyzers yara \
    --format "$FORMAT" \
    | tee "$OUTPUT_FILE"

echo ""
echo "=========================================="
echo "Scan completed!"
echo "Results saved to: $OUTPUT_FILE"
echo "=========================================="


# # Just filename (uses default server URL and format)
# ./run_yara.sh yara_scan_res_mcp_malicious_description.txt

# # With URL and filename
# ./run_yara.sh http://192.168.174.129:8000/sse detailed yara_scan_res_mcp_malicious_description.txt

# # No arguments (auto-generates filename)
# ./run_yara.sh
