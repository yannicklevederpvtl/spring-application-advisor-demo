# Application Advisor MCP Configuration Guide

Application Advisor **1.6** exposes MCP via the CLI — **no Application Advisor Server required**.

Reference: [IDE integration using MCP](https://techdocs.broadcom.com/us/en/vmware-tanzu/spring/application-advisor/1-6/app-advisor/model-context-protocol-server.html)

## Minimal configuration

Copy from `config/mcp-settings.json` or use:

```json
{
  "mcpServers": {
    "advisor-mcp-server": {
      "command": "bash",
      "args": ["-c", "advisor mcp"],
      "transportType": "stdio"
    }
  }
}
```

## Enterprise lab (optional Artifactory)

If you installed **Enterprise lab** mode with local Artifactory, add:

```json
{
  "mcpServers": {
    "advisor-mcp-server": {
      "command": "bash",
      "args": ["-c", "advisor mcp"],
      "transportType": "stdio",
      "env": {
        "ARTIFACTORY_REPOSITORY_URL": "http://localhost:8082/artifactory"
      }
    }
  }
}
```

MCP clients **do not inherit shell environment variables**. Add any required variables (`REGISTRY_TOKEN`, `BROADCOM_ARTIFACTORY_EMAIL`, custom mapping paths) to the `env` block.

## Claude Desktop

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Merge the `advisor-mcp-server` entry into existing `mcpServers`, then restart Claude Desktop.

## VS Code / Cline

Add the same JSON to your MCP settings file (e.g. `cline_mcp_settings.json`).

## Prerequisites

```bash
which advisor    # must be in PATH (install via ./install.sh)
advisor -v       # 1.6.3
```

## How it works

```
MCP Client ←→ [STDIO] ←→ advisor mcp ←→ local Advisor CLI (upgrade-plan, build-config, …)
```

## Test prompts

- "Get the upgrade plan for my Spring application"
- "Show me the build configuration"
- "Help me upgrade Spring Boot from 2.7 to 4.0"

## Troubleshooting

| Issue | Fix |
|---|---|
| `advisor: command not found` | Run `./install.sh` or add `/usr/local/bin` to PATH |
| MCP tools unavailable | Restart MCP client after config change |
| Missing env vars | Add them explicitly in the MCP `env` block |
