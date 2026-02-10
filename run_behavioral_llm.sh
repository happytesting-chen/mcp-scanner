
#!/bin/bash

# MCP Scanner Script - Behavioral Analyzer Only
# Scans local MCP server source code for behavioral mismatches
# Uses OpenAI API key from .env file

# Activate virtual environment
source .venv/bin/activate

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set LLM configuration - OpenAI only (required for behavioral analyzer)
if [ -n "$OPENAI_API_KEY" ]; then
    export MCP_SCANNER_LLM_API_KEY="$OPENAI_API_KEY"
    export MCP_SCANNER_LLM_MODEL="${MCP_SCANNER_LLM_MODEL:-gpt-4o}"
    echo "Using OpenAI API with model: ${MCP_SCANNER_LLM_MODEL}"
else
    echo "Error: OPENAI_API_KEY not found in .env file (required for behavioral analyzer)"
    exit 1
fi

# Parse arguments - first arg is source path (file or directory), second is output filename
DEFAULT_SOURCE_PATH="/mnt/c/Users/Intern/Documents/local_mcp_server/"

if [[ "$1" == http://* ]] || [[ "$1" == https://* ]]; then
    echo "Error: Behavioral analyzer requires a local file/directory path, not a URL"
    echo "Usage: ./run_behavioral_llm.sh [source_path] [output_filename]"
    exit 1
elif [ -z "$1" ]; then
    # No arguments - use default source path
    SOURCE_PATH="$DEFAULT_SOURCE_PATH"
    OUTPUT_FILENAME="behavioral_local_mcp_res.txt"
elif [ -d "$1" ]; then
    # First argument is a directory
    SOURCE_PATH="$1"
    OUTPUT_FILENAME="${2:-behavioral_scan_$(date +%Y%m%d_%H%M%S).txt}"
elif [ -f "$1" ]; then
    # First argument is a file
    SOURCE_PATH="$1"
    OUTPUT_FILENAME="${2:-behavioral_scan_$(date +%Y%m%d_%H%M%S).txt}"
else
    # First argument might be output filename (if default path exists)
    if [ -d "$DEFAULT_SOURCE_PATH" ] || [ -f "$DEFAULT_SOURCE_PATH" ]; then
        SOURCE_PATH="$DEFAULT_SOURCE_PATH"
        OUTPUT_FILENAME="$1"
    else
        echo "Error: Source path '$1' not found (must be a file or directory)"
        echo "Usage: ./run_behavioral_llm.sh [source_path] [output_filename]"
        echo "  source_path can be:"
        echo "    - A Python file (.py)"
        echo "    - A directory containing Python files"
        exit 1
    fi
fi

# Validate that source path is a Python file or directory
if [ -f "$SOURCE_PATH" ] && [[ ! "$SOURCE_PATH" == *.py ]]; then
    echo "Warning: File '$SOURCE_PATH' does not have .py extension"
    echo "Behavioral analyzer works best with Python files"
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"

# Full output file path
OUTPUT_FILE="$OUTPUT_DIR/$OUTPUT_FILENAME"

# Format (default: detailed)
FORMAT="${FORMAT:-detailed}"

echo "=========================================="
echo "MCP Scanner - Behavioral Analyzer"
echo "=========================================="
echo "Source Path: $SOURCE_PATH"
echo "LLM Model: $MCP_SCANNER_LLM_MODEL"
echo "Format: $FORMAT"
echo "Output File: $OUTPUT_FILE"
echo "=========================================="
echo ""

# Print the exact command that will be executed
echo "Executing command:"
echo "mcp-scanner behavioral \"$SOURCE_PATH\" --format \"$FORMAT\" | tee \"$OUTPUT_FILE\""
echo ""

# Run the scanner with behavioral analyzer and save output to file
mcp-scanner \
    behavioral \
    "$SOURCE_PATH" \
    --format "$FORMAT" \
    | tee "$OUTPUT_FILE"

echo ""
echo "=========================================="
echo "Scan completed!"
echo "Results saved to: $OUTPUT_FILE"
echo "=========================================="


# Scan a directory (default)
#./run_behavioral_llm.sh /mnt/c/Users/Intern/Documents/local_mcp_server/

# Scan a single Python file
# ./run_behavioral_llm.sh /path/to/server.py behavioral_results.txt

# # Scan directory with custom output filename
# ./run_behavioral_llm.sh /path/to/mcp_server/ my_results.txt

# # Scan single file with custom output filename
# ./run_behavioral_llm.sh /path/to/server.py my_results.txt

# # No arguments (uses default path)
# ./run_behavioral_llm.sh
