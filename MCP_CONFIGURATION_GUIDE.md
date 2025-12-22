# Application Advisor MCP Configuration Guide

This guide provides the exact configuration to connect to your Application Advisor server running on Docker (port 9003) using the `advisor mcp` command.

## Configuration

The configuration uses the `advisor mcp` STDIO command, which connects to your Docker-deployed server via the `ADVISOR_SERVER` environment variable.

### Configuration JSON

```json
{
  "mcpServers": {
    "advisor-mcp-server": {
      "command": "bash",
      "args": ["-c", "advisor mcp"],
      "transportType": "stdio",
      "env": {
        "ADVISOR_SERVER": "http://localhost:9003",
        "ARTIFACTORY_REPOSITORY_URL": "http://localhost:8082/artifactory"
      }
    }
  }
}
```

## Setup Instructions

### For Claude Desktop

1. **Locate your Claude Desktop configuration file:**
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`

2. **Open the configuration file** (create it if it doesn't exist)

3. **Add or merge the configuration:**
   - If the file is empty or doesn't exist, use the JSON above
   - If the file already has `mcpServers`, add the `advisor-mcp-server` entry to the existing `mcpServers` object

4. **Example of merged configuration:**
   ```json
   {
     "mcpServers": {
       "existing-server": {
         "command": "...",
         ...
       },
       "advisor-mcp-server": {
         "command": "bash",
         "args": ["-c", "advisor mcp"],
         "transportType": "stdio",
         "env": {
           "ADVISOR_SERVER": "http://localhost:9003",
           "ARTIFACTORY_REPOSITORY_URL": "http://localhost:8082/artifactory"
         }
       }
     }
   }
   ```

5. **Restart Claude Desktop**

6. **Verify it's working:**
   - Open Claude Desktop
   - You should see "advisor-mcp-server" in the MCP servers list
   - Try asking: "Help me upgrade my Spring application"

### For Cline (VS Code Extension)

1. **Open VS Code**

2. **Open the Cline extension settings:**
   - Click on the Cline extension icon
   - Navigate to "MCP Servers" or "Settings"

3. **Create or edit the MCP settings file:**
   - The file is typically: `cline_mcp_settings.json`
   - Location may vary, check Cline documentation

4. **Add the configuration:**
   ```json
   {
     "mcpServers": {
       "advisor-mcp-server": {
         "command": "bash",
         "args": ["-c", "advisor mcp"],
         "transportType": "stdio",
         "env": {
           "ADVISOR_SERVER": "http://localhost:9003",
           "ARTIFACTORY_REPOSITORY_URL": "http://localhost:8082/artifactory"
         }
       }
     }
   }
   ```

5. **Reload VS Code or restart the Cline extension**

### For Other MCP Clients

Use the same JSON configuration structure. The key points are:
- **command**: `bash`
- **args**: `["-c", "advisor mcp"]`
- **transportType**: `stdio`
- **env.ADVISOR_SERVER**: `http://localhost:9003`
- **env.ARTIFACTORY_REPOSITORY_URL**: `http://localhost:8082/artifactory` (optional, but recommended)

## Prerequisites

1. **Advisor CLI installed:**
   ```bash
   which advisor
   ```
   Should return: `/usr/local/bin/advisor` (or similar)

   If not installed, run: `./install.sh`

2. **Advisor Server running:**
   ```bash
   docker ps | grep spring-server
   curl http://localhost:9003/actuator/health
   ```
   Should return HTTP 200

3. **Artifactory running (optional but recommended):**
   ```bash
   docker ps | grep artifactory
   curl http://localhost:8082/artifactory/api/system/ping
   ```

## Troubleshooting

### "advisor: command not found"

**Solution:** The advisor CLI is not in your PATH or not installed.

1. Check if it exists: `ls -la /usr/local/bin/advisor`
2. If missing, run: `./install.sh`
3. Verify: `which advisor`

### "Connection refused" or "Cannot connect to advisor server"

**Solution:** The advisor server Docker container is not running.

1. Check container status: `docker ps | grep spring-server`
2. If not running, start it: `docker start spring-server`
3. Verify health: `curl http://localhost:9003/actuator/health`

### MCP server not appearing in client

**Solution:** Check the configuration file syntax and restart the client.

1. Validate JSON syntax (use a JSON validator)
2. Ensure the file path is correct
3. Restart the MCP client completely
4. Check client logs for errors

### Environment variables not working

**Solution:** MCP servers don't inherit shell environment variables. All required variables must be in the `env` section of the configuration.

If you need additional environment variables (like `BROADCOM_ARTIFACTORY_TOKEN`), add them to the `env` section:

```json
{
  "mcpServers": {
    "advisor-mcp-server": {
      "command": "bash",
      "args": ["-c", "advisor mcp"],
      "transportType": "stdio",
      "env": {
        "ADVISOR_SERVER": "http://localhost:9003",
        "ARTIFACTORY_REPOSITORY_URL": "http://localhost:8082/artifactory",
        "BROADCOM_ARTIFACTORY_EMAIL": "your-email@example.com",
        "BROADCOM_ARTIFACTORY_TOKEN": "your-token-here"
      }
    }
  }
}
```

## How It Works

1. **MCP Client** (Claude Desktop, Cline, etc.) starts the `advisor mcp` command via STDIO
2. **Advisor MCP Server** (`advisor mcp`) runs as a STDIO MCP server
3. **Advisor CLI** communicates with your **Application Advisor Server** (Docker on port 9003) via HTTP REST API
4. The MCP tools (upgrade-plan, build-config, etc.) are exposed to your MCP client

```
MCP Client ←→ [STDIO] ←→ advisor mcp ←→ [HTTP REST] ←→ Application Advisor Server (port 9003)
```

## Testing

After configuration, test with these prompts in your MCP client:

- "Get the upgrade plan for my Spring application"
- "Show me the build configuration"
- "Help me upgrade Spring Boot from 2.7 to 4.0"

The advisor MCP tools should be available and functional.

