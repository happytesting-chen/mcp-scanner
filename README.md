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

#### Environment setup 
configure your own open ai api key(OPENAI_API_KEY) in your local env. the code will load from your local envoriment

#### For SCAN_MODE="behavioral":
```
SOURCE_PATH="/mnt/c/Users/Intern/Documents/local_mcp_server/local_mcp_demo.py"
```
#### run the Behavioral Code Scanning
```
bash run.sh
```
```


See [Behavioral Scanning Documentation](https://github.com/cisco-ai-defense/mcp-scanner/tree/main/docs/behavioral-scanning.md) for complete technical details.


