#!/bin/bash

# MCP Scanner Script - YARA Analyzer for Python Files
# Scans local Python file content using YARA rules (no LLM required)

# Activate virtual environment
source .venv/bin/activate

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Parse arguments - first arg is Python file path, second is output filename
if [[ "$1" == http://* ]] || [[ "$1" == https://* ]]; then
    echo "Error: This script scans local Python files, not URLs"
    echo "Usage: ./run_yara_file.sh <python_file> [output_filename]"
    exit 1
elif [ -z "$1" ]; then
    echo "Error: Python file path is required"
    echo "Usage: ./run_yara_file.sh <python_file> [output_filename]"
    echo "Example: ./run_yara_file.sh /path/to/server.py yara_scan_results.txt"
    exit 1
elif [ ! -f "$1" ]; then
    echo "Error: File '$1' not found"
    exit 1
else
    PYTHON_FILE="$1"
    OUTPUT_FILENAME="${2:-yara_file_scan_$(date +%Y%m%d_%H%M%S).txt}"
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"

# Full output file path
OUTPUT_FILE="$OUTPUT_DIR/$OUTPUT_FILENAME"

echo "=========================================="
echo "MCP Scanner - YARA File Analyzer"
echo "=========================================="
echo "Python File: $PYTHON_FILE"
echo "Output File: $OUTPUT_FILE"
echo "=========================================="
echo ""

# Read Python file content and scan with YARA using Python
python3 << EOF | tee "$OUTPUT_FILE"
import asyncio
import sys
from pathlib import Path
from mcpscanner.core.analyzers.yara_analyzer import YaraAnalyzer

async def scan_file():
    file_path = "$PYTHON_FILE"
    
    # Read file content
    with open(file_path, 'r', encoding='utf-8') as f:
        file_content = f.read()
    
    # Initialize YARA analyzer
    analyzer = YaraAnalyzer()
    
    # Scan the file content
    context = {
        "tool_name": Path(file_path).name,
        "content_type": "source_code",
        "file_path": file_path
    }
    
    findings = await analyzer.analyze(file_content, context)
    
    # Print results
    print("=== YARA File Scan Results ===")
    print(f"File: {file_path}")
    print(f"Content Length: {len(file_content)} characters")
    print(f"Findings: {len(findings)}")
    print("")
    
    if findings:
        print("⚠️  THREATS DETECTED:")
        print("")
        for i, finding in enumerate(findings, 1):
            print(f"Finding {i}:")
            print(f"  Severity: {finding.severity}")
            print(f"  Summary: {finding.summary}")
            print(f"  Threat Category: {finding.threat_category}")
            if finding.details:
                print(f"  Evidence: {finding.details.get('evidence', 'N/A')}")
            print("")
    else:
        print("✅ No threats detected")
    
    return findings

if __name__ == "__main__":
    findings = asyncio.run(scan_file())
    sys.exit(0 if len(findings) == 0 else 1)
EOF

SCAN_EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Scan completed!"
echo "Results saved to: $OUTPUT_FILE"
echo "=========================================="

exit $SCAN_EXIT_CODE


# # Usage examples:
# # Scan Python file
# ./run_yara_file.sh /path/to/mcp_server.py yara_file_scan_results.txt
#
# # Auto-generate filename
# ./run_yara_file.sh /path/to/server.py

