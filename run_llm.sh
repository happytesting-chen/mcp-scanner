#!/bin/bash

# MCP Scanner Script - LLM Analyzer Only
# Uses OpenAI API key from .env file

# Activate virtual environment
source .venv/bin/activate

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set LLM configuration - OpenAI only
if [ -n "$OPENAI_API_KEY" ]; then
    export MCP_SCANNER_LLM_API_KEY="$OPENAI_API_KEY"
    export MCP_SCANNER_LLM_MODEL="${MCP_SCANNER_LLM_MODEL:-gpt-4o}"
    echo "Using OpenAI API with model: ${MCP_SCANNER_LLM_MODEL}"
else
    echo "Error: OPENAI_API_KEY not found in .env file"
    exit 1
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
echo "MCP Scanner - LLM Analyzer"
echo "=========================================="
echo "Server URL: $SERVER_URL"
echo "LLM Model: $MCP_SCANNER_LLM_MODEL"
echo "Format: $FORMAT"
echo "Output File: $OUTPUT_FILE"
echo "=========================================="
echo ""

# Run the scanner with LLM analyzer and save output to file
mcp-scanner \
    --server-url "$SERVER_URL" \
    --analyzers llm \
    --format "$FORMAT" \
    | tee "$OUTPUT_FILE"

echo ""
echo "=========================================="
echo "Scan completed!"
echo "Results saved to: $OUTPUT_FILE"
echo "=========================================="


# # Just filename (uses default server URL and format)
# ./run_llm.sh llm_scan_res_mcp_malicious_desciption.txt

# # With URL and filename
# ./run_llm.sh http://192.168.174.129:8000/sse detailed llm_scan_res_mcp_malicious_desciption.txt

# # No arguments (auto-generates filename)
# ./run_llm.sh