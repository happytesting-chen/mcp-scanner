#!/bin/bash

# ============================================================
# MCP Scanner - Unified Configuration Script
# ============================================================
# Edit the variables below to configure your scan.
# Then run: ./run.sh
# ============================================================

# -----------------------------------------------------------
# 1. SCAN MODE (choose one)
# -----------------------------------------------------------
# Options:
#   "behavioral"  - Scan local source code for docstring/behavior mismatches (requires LLM)
#   "remote"      - Scan a remote MCP server via URL (SSE transport)
#   "stdio"       - Scan a local MCP server via stdio transport
SCAN_MODE="behavioral" #"remote" #"stdio" #"behavioral"

# -----------------------------------------------------------
# 2. ANALYZERS
# -----------------------------------------------------------
# Comma-separated list. Options: yara, llm, behavioral, api
# - For SCAN_MODE="behavioral": leave empty (behavioral subcommand handles it)
# - For SCAN_MODE="remote":     e.g. "yara", "llm", "yara,llm", "api,yara,llm"
# - For SCAN_MODE="stdio":      e.g. "yara", "llm", "yara,llm"
ANALYZERS="llm" #"yara,llm"

# -----------------------------------------------------------
# 3. LLM CONFIGURAT ION (required for llm/behavioral analyzers)
# -----------------------------------------------------------

LLM_API_KEY=""          # Your OpenAI/Anthropic API key (e.g. "sk-xxx")
LLM_MODEL="gpt-4o"      # Model name (e.g. "gpt-4o", "anthropic/claude-3-5-sonnet")

# -----------------------------------------------------------
# 4. SOURCE / TARGET CONFIGURATION
# -----------------------------------------------------------
# For SCAN_MODE="behavioral":
SOURCE_PATH="/mnt/c/Users/Intern/Documents/local_mcp_server/local_mcp_demo.py"

# For SCAN_MODE="remote":
SERVER_URL="http://192.168.174.129:8000/sse"

# For SCAN_MODE="stdio":
STDIO_COMMAND="python3"         # e.g. "python3" or "uvx"
STDIO_ARGS=""                   # Leave empty to auto-use SOURCE_PATH above
                                # Or set manually, e.g. "--from,mcp-pkg,mcp-server"

# -----------------------------------------------------------
# 5. OUTPUT CONFIGURATION
# -----------------------------------------------------------
OUTPUT_DIR="output"
OUTPUT_FILENAME=""       # Leave empty for auto-generated filename
FORMAT="detailed"        # Options: raw, summary, detailed, by_tool, by_analyzer, by_severity, table

# -----------------------------------------------------------
# 6. OPTIONAL SETTINGS
# -----------------------------------------------------------
RULES_PATH=""            # Custom YARA rules directory (leave empty for default)
VERBOSE=false            # Set to true for verbose output
HIDE_SAFE=false          # Set to true to hide safe tools from output
SHOW_STATS=false         # Set to true to show scan statistics

# ============================================================
# DO NOT EDIT BELOW THIS LINE (unless you know what you're doing)
# ============================================================

# Activate virtual environment
source my-env/bin/activate

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Unset ANTHROPIC_API_KEY to prevent litellm from auto-detecting it
unset ANTHROPIC_API_KEY

# Set LLM environment variables
# Priority: script config > .env file > environment
if [ -n "$LLM_API_KEY" ]; then
    export MCP_SCANNER_LLM_API_KEY="$LLM_API_KEY"
elif [ -n "$OPENAI_API_KEY" ]; then
    export MCP_SCANNER_LLM_API_KEY="$OPENAI_API_KEY"
fi

if [ -n "$LLM_MODEL" ]; then
    export MCP_SCANNER_LLM_MODEL="$LLM_MODEL"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Auto-generate output filename if not set
if [ -z "$OUTPUT_FILENAME" ]; then
    OUTPUT_FILENAME="${SCAN_MODE}_scan_$(date +%Y%m%d_%H%M%S).txt"
fi
OUTPUT_FILE="$OUTPUT_DIR/$OUTPUT_FILENAME"

# Build optional flags
OPTIONAL_FLAGS=""
if [ -n "$RULES_PATH" ]; then
    OPTIONAL_FLAGS="$OPTIONAL_FLAGS --rules-path $RULES_PATH"
fi
if [ "$VERBOSE" = true ]; then
    OPTIONAL_FLAGS="$OPTIONAL_FLAGS --verbose"
fi
if [ "$HIDE_SAFE" = true ]; then
    OPTIONAL_FLAGS="$OPTIONAL_FLAGS --hide-safe"
fi
if [ "$SHOW_STATS" = true ]; then
    OPTIONAL_FLAGS="$OPTIONAL_FLAGS --stats"
fi

# Print configuration
echo "=========================================="
echo "MCP Scanner - Unified Runner"
echo "=========================================="
echo "Scan Mode:   $SCAN_MODE"
echo "Format:      $FORMAT"
echo "Output File: $OUTPUT_FILE"

# Build and run the command based on scan mode
case "$SCAN_MODE" in

    behavioral)
        if [ -z "$SOURCE_PATH" ]; then
            echo "Error: SOURCE_PATH is required for behavioral scan mode"
            exit 1
        fi
        echo "Source Path: $SOURCE_PATH"
        echo "LLM Model:  $MCP_SCANNER_LLM_MODEL"
        echo "=========================================="
        echo ""

        CMD="mcp-scanner behavioral \"$SOURCE_PATH\" --format $FORMAT $OPTIONAL_FLAGS"
        echo "Executing command:"
        echo "$CMD | tee \"$OUTPUT_FILE\""
        echo ""

        mcp-scanner \
            behavioral \
            "$SOURCE_PATH" \
            --format "$FORMAT" \
            $OPTIONAL_FLAGS \
            | tee "$OUTPUT_FILE"
        ;;

    remote)
        if [ -z "$SERVER_URL" ]; then
            echo "Error: SERVER_URL is required for remote scan mode"
            exit 1
        fi
        echo "Server URL:  $SERVER_URL"
        echo "Analyzers:   $ANALYZERS"
        if echo "$ANALYZERS" | grep -q "llm"; then
            echo "LLM Model:  $MCP_SCANNER_LLM_MODEL"
        fi
        echo "=========================================="
        echo ""

        CMD="mcp-scanner --server-url \"$SERVER_URL\" --analyzers $ANALYZERS --format $FORMAT $OPTIONAL_FLAGS"
        echo "Executing command:"
        echo "$CMD | tee \"$OUTPUT_FILE\""
        echo ""

        mcp-scanner \
            --server-url "$SERVER_URL" \
            --analyzers "$ANALYZERS" \
            --format "$FORMAT" \
            $OPTIONAL_FLAGS \
            | tee "$OUTPUT_FILE"
        ;;

    stdio)
        if [ -z "$STDIO_COMMAND" ]; then
            echo "Error: STDIO_COMMAND is required for stdio scan mode"
            exit 1
        fi

        # If STDIO_ARGS is empty, auto-use SOURCE_PATH as the argument
        if [ -z "$STDIO_ARGS" ] && [ -n "$SOURCE_PATH" ]; then
            STDIO_ARGS="$SOURCE_PATH"
        fi

        if [ -z "$STDIO_ARGS" ]; then
            echo "Error: STDIO_ARGS (or SOURCE_PATH) is required for stdio scan mode"
            exit 1
        fi

        echo "Command:     $STDIO_COMMAND $STDIO_ARGS"
        echo "Analyzers:   $ANALYZERS"
        if echo "$ANALYZERS" | grep -q "llm"; then
            echo "LLM Model:  $MCP_SCANNER_LLM_MODEL"
        fi
        echo "=========================================="
        echo ""

        # Build stdio-arg flags (supports file paths with spaces)
        # Split STDIO_ARGS by comma into individual --stdio-arg flags
        STDIO_ARG_FLAGS=""
        IFS=',' read -ra ARG_ARRAY <<< "$STDIO_ARGS"
        for arg in "${ARG_ARRAY[@]}"; do
            STDIO_ARG_FLAGS="$STDIO_ARG_FLAGS --stdio-arg=$arg"
        done

        CMD="mcp-scanner --analyzers $ANALYZERS --format $FORMAT $OPTIONAL_FLAGS stdio --stdio-command $STDIO_COMMAND $STDIO_ARG_FLAGS"
        echo "Executing command:"
        echo "$CMD | tee \"$OUTPUT_FILE\""
        echo ""

        mcp-scanner \
            --analyzers "$ANALYZERS" \
            --format "$FORMAT" \
            $OPTIONAL_FLAGS \
            stdio \
            --stdio-command "$STDIO_COMMAND" \
            $STDIO_ARG_FLAGS \
            | tee "$OUTPUT_FILE"
        ;;

    *)
        echo "Error: Invalid SCAN_MODE '$SCAN_MODE'"
        echo "Options: behavioral, remote, stdio"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Scan completed!"
echo "Results saved to: $OUTPUT_FILE"
echo "=========================================="
