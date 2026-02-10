# MCP Scanner

A Python tool for scanning MCP (Model Context Protocol) servers and tools for potential security findings. The MCP Scanner combines Cisco AI Defense inspect API, YARA rules and LLM-as-a-judge to detect malicious MCP tools.




## Installation

### Prerequisites

- Python 3.11+
- uv (Python package manager)
- LLM Provider API Key 



### Installing from Source

```bash
git clone https://github.com/happytesting-chen/mcp-scanner
cd mcp-scanner
# Install with uv (recommended)
uv venv -p <Python version less than or equal to 3.13> /path/to/your/choice/of/venv/directory
source /path/to/your/choice/of/venv/directory/bin/activate
uv pip install .
```

## Quick Start

### Environment setup 
configure your own open ai api key(OPENAI_API_KEY) in your local env. the code will load from your local envoriment

# For SCAN_MODE="behavioral":
SOURCE_PATH="/mnt/c/Users/Intern/Documents/local_mcp_server/local_mcp_demo.py"

# run the scan
bash run.sh

#### Behavioral Code Scanning

The Behavioral Analyzer performs advanced static analysis of MCP server source code to detect behavioral mismatches between docstring claims and actual implementation. It uses LLM-powered alignment checking combined with cross-file dataflow tracking.

```bash
# Scan a single Python file
mcp-scanner behavioral /path/to/mcp_server.py

# Scan a directory
mcp-scanner behavioral /path/to/mcp_servers/

# With specific output format
mcp-scanner behavioral /path/to/mcp_server.py --format by_severity

# Detailed analysis with all findings
mcp-scanner behavioral /path/to/mcp_server.py --format detailed

# Save results to file
mcp-scanner behavioral /path/to/mcp_server.py --output results.json --format raw
```


See [Behavioral Scanning Documentation](https://github.com/cisco-ai-defense/mcp-scanner/tree/main/docs/behavioral-scanning.md) for complete technical details.


