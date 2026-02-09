# MCP Servers Configuration

**Purpose**  
This document explains how to configure MCP (Model Context Protocol) servers for conversational AI projects.

---

## Configuration File

Copy `mcp_servers.example.json` to `mcp_servers.json` and customize for your environment:

```bash
cp config/mcp_servers.example.json config/mcp_servers.json
```

**Note**: `mcp_servers.json` is gitignored - never commit credentials or secrets.

---

## Configuration Structure

### Root Level

```json
{
  "servers": {
    "server_name": { ... }
  },
  "default_timeout_seconds": 30,
  "max_retries": 3,
  "auto_reconnect": true
}
```

| Field | Type | Description |
|-------|------|-------------|
| `servers` | object | Map of server names to server configurations |
| `default_timeout_seconds` | number | Default timeout for tool invocations (optional) |
| `max_retries` | number | Maximum retry attempts on failure (optional) |
| `auto_reconnect` | boolean | Automatically reconnect on connection loss (optional) |

### Server Configuration

Each server in the `servers` object has the following structure:

```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-postgres"],
  "env": {
    "DATABASE_URL": "postgresql://..."
  },
  "description": "Optional description"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `command` | string | Yes | Command to execute (e.g., `npx`, `python`, `node`) |
| `args` | array | Yes | Command-line arguments |
| `env` | object | No | Environment variables (supports `${VAR}` substitution) |
| `description` | string | No | Human-readable server description |

---

## Server Examples

### Database Server (PostgreSQL)

```json
{
  "database_server": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres"],
    "env": {
      "DATABASE_URL": "postgresql://user:password@localhost:5432/dbname"
    }
  }
}
```

**Tools Provided:**
- `query_database` - Execute SELECT queries
- `execute_sql` - Execute INSERT/UPDATE/DELETE statements
- `list_tables` - List database tables
- `describe_table` - Get table schema

### API Server

```json
{
  "api_server": {
    "command": "python",
    "args": ["-m", "mcp_server_api"],
    "env": {
      "API_BASE_URL": "https://api.example.com",
      "API_KEY": "${API_KEY}"
    }
  }
}
```

**Tools Provided:**
- `http_request` - Make HTTP requests (GET, POST, PUT, DELETE)
- `list_endpoints` - List available API endpoints

### File System Server

```json
{
  "filesystem_server": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem"],
    "env": {
      "ALLOWED_DIRECTORIES": "/data:/tmp:/var/log"
    }
  }
}
```

**Tools Provided:**
- `read_file` - Read file contents
- `write_file` - Write file contents
- `list_directory` - List directory contents
- `create_directory` - Create directories

### GitHub Server

```json
{
  "github_server": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-github"],
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
    }
  }
}
```

**Tools Provided:**
- `create_issue` - Create GitHub issues
- `list_issues` - List repository issues
- `get_file` - Get file contents from repository
- `search_code` - Search repository code

### Brave Search Server

```json
{
  "brave_search_server": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-brave-search"],
    "env": {
      "BRAVE_API_KEY": "${BRAVE_API_KEY}"
    }
  }
}
```

**Tools Provided:**
- `search` - Perform web searches
- `search_news` - Search news articles

---

## Environment Variable Substitution

Environment variables can be referenced using `${VAR_NAME}` syntax:

```json
{
  "env": {
    "API_KEY": "${API_KEY}",
    "DATABASE_URL": "${DATABASE_URL}"
  }
}
```

The MCP client will substitute these values from your environment at runtime.

---

## Server Discovery

After configuring servers:

1. **MCP Client** loads configuration from `config/mcp_servers.json`
2. **Connects** to each configured server
3. **Discovers** tools from each server via `list_tools()`
4. **Registers** tools in `exp.mcp_tools` database table
5. **Assigns** tools to variants via `exp.variant_tools` table

---

## Security Best Practices

1. **Never commit `mcp_servers.json`** - Use `.gitignore` to exclude it
2. **Use environment variables** - Store secrets in environment, not config file
3. **Limit file system access** - Use `ALLOWED_DIRECTORIES` to restrict file system server access
4. **Use read-only credentials** - Prefer read-only database users when possible
5. **Rotate API keys** - Regularly rotate API keys and tokens

---

## Troubleshooting

### Server Won't Start

- Check that `command` is available in PATH
- Verify `args` are correct for the server package
- Check environment variables are set correctly

### Tools Not Discovered

- Verify server connection is successful
- Check server logs for errors
- Ensure server implements MCP protocol correctly

### Connection Timeouts

- Increase `default_timeout_seconds` in config
- Check network connectivity to server
- Verify server is running and accessible

---

## Related Documentation

- **[../docs/mcp-integration.md](../docs/mcp-integration.md)**: MCP integration guide
- **[../docs/data-model.md](../docs/data-model.md)**: Database schema (section 5: Tool Registry)

---

## After Reading This Document

You will understand:
- How to configure MCP servers
- What server types are available
- How to use environment variable substitution
- Security best practices for server configuration

**Next Step**: Copy `mcp_servers.example.json` to `mcp_servers.json` and customize for your environment
