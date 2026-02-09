# MCP Integration Guide

**Purpose**  
This document specifies the MCP (Model Context Protocol) client library wrappers and integration patterns for connecting conversational AI projects to external tools, data sources, and workflows.

---

## Start Here If…

- **Integrating MCP servers** → Read this document
- **Using MCP tools in flows** → Focus on Tool Discovery and Invocation sections
- **Setting up MCP servers** → See [config/mcp_servers.example.json](../config/mcp_servers.example.json) (coming in Phase 4)
- **Understanding tool registry** → See [data-model.md](data-model.md) section 5

---

## 1. Overview

### 1.1 What is MCP?

The Model Context Protocol (MCP) is an open standard that standardizes how AI applications connect to external tools, data sources, and workflows. MCP provides:

- **Standardized Interface**: Common protocol for tool discovery and invocation
- **Client-Server Architecture**: Lightweight servers expose capabilities to AI clients
- **Platform Agnostic**: Works with any MCP-compatible server implementation
- **Tool Discovery**: Automatic discovery of available tools from servers
- **Type Safety**: Structured tool schemas ensure correct usage

### 1.2 Why Use MCP?

MCP enables conversational AI projects to:

- **Extend Capabilities**: Connect to databases, APIs, file systems, and more
- **Standardize Integration**: Use consistent patterns across different tools
- **Enable Experimentation**: Test different tool combinations via variant assignment
- **Maintain Security**: Centralized tool access control and validation
- **Simplify Development**: Pre-built servers for common use cases

### 1.3 Integration Layer Components

This integration layer provides:

- **Tool Discovery**: Automatically discover tools from configured MCP servers
- **Tool Invocation**: Execute tools with proper error handling and retries
- **Connection Management**: Manage multiple concurrent MCP server connections
- **Tool Registry Integration**: Register discovered tools in database for variant assignment
- **Flow Integration**: Use tools in conversation flow actions

### 1.1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Conversational AI Application                  │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │   Flow       │ ──►│   MCP        │ ──►│   Tool       │ │
│  │   Engine     │    │   Client     │    │   Registry   │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         │                    │                    │       │
│         │                    ▼                    │       │
│         │            ┌──────────────┐             │       │
│         │            │   MCP        │             │       │
│         │            │   Servers    │             │       │
│         │            └──────────────┘             │       │
│         │                    │                    │       │
│         └────────────────────┼────────────────────┘       │
│                              │                            │
│                              ▼                            │
│                    ┌──────────────┐                       │
│                    │   Database   │                       │
│                    │   (Tools)    │                       │
│                    └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

### 1.4 Integration Flow

```
1. Configure MCP servers in config/mcp_servers.json
2. MCP client connects to servers on startup
3. Tools are discovered from each server
4. Tools are registered in exp.mcp_tools table
5. Tools are assigned to variants via exp.variant_tools
6. Flow orchestrator includes tools in prompts for LLM access
7. Tools are invoked during conversation flow execution
```

---

## 2. Common Integration Patterns

### 2.1 Pattern: Database Query in Flow

**Use Case**: Query database during conversation to provide dynamic information.

**Implementation**:

```python
# In flow action
{
    "type": "call_api",
    "server_name": "database_server",
    "tool_name": "query_database",
    "arguments": {
        "query": "SELECT name, email FROM users WHERE id = $1",
        "parameters": ["{{user_id}}"]
    },
    "result_field": "user_info"
}
```

**Flow State**:

```yaml
get_user_info:
  type: data_collection
  message: "Let me look up your account information..."
  actions:
    - type: call_api
      server_name: database_server
      tool_name: query_database
      arguments:
        query: "SELECT name, email FROM users WHERE id = $1"
        parameters: ["{{user_id}}"]
      result_field: user_info
```

### 2.2 Pattern: External API Call

**Use Case**: Call external APIs to fetch data or perform actions.

**Implementation**:

```python
# In flow action
{
    "type": "call_api",
    "server_name": "api_server",
    "tool_name": "http_request",
    "arguments": {
        "method": "GET",
        "url": "/users/{{user_id}}/orders",
        "headers": {
            "Authorization": "Bearer {{api_token}}"
        }
    },
    "result_field": "orders"
}
```

### 2.3 Pattern: File System Operations

**Use Case**: Read or write files during conversation (e.g., generating reports).

**Implementation**:

```python
# In flow action
{
    "type": "call_api",
    "server_name": "filesystem_server",
    "tool_name": "write_file",
    "arguments": {
        "path": "/tmp/user_report_{{user_id}}.json",
        "content": "{{report_data}}"
    }
}
```

### 2.4 Pattern: Multi-Tool Workflow

**Use Case**: Chain multiple tools together for complex operations.

**Implementation**:

```python
# Sequential tool calls in flow
actions:
  - type: call_api
    server_name: database_server
    tool_name: query_database
    arguments:
      query: "SELECT * FROM orders WHERE user_id = $1"
      parameters: ["{{user_id}}"]
    result_field: orders
  
  - type: call_api
    server_name: api_server
    tool_name: http_request
    arguments:
      method: "POST"
      url: "/analytics/process"
      body:
        orders: "{{orders}}"
    result_field: analytics_result
```

### 2.5 Pattern: Conditional Tool Usage

**Use Case**: Use different tools based on conversation context.

**Implementation**:

```yaml
# Flow with conditional tool selection
states:
  process_request:
    type: data_collection
    message: "What would you like to do?"
    transitions:
      - from: process_request
        to: query_database_state
        condition:
          type: equals
          field: user_response
          value: "lookup"
      
      - from: process_request
        to: call_api_state
        condition:
          type: equals
          field: user_response
          value: "api"
```

---

## 3. MCP Client Library Wrappers

### 2.1 Python Wrapper

#### 2.1.1 Installation

```bash
pip install mcp anthropic python-dotenv
```

#### 2.1.2 Basic Usage

```python
from mcp_client import MCPClient, MCPServerConfig

# Create client
client = MCPClient()

# Connect to server
server_config = MCPServerConfig(
    name="database_server",
    command="npx",
    args=["-y", "@modelcontextprotocol/server-postgres"],
    env={"DATABASE_URL": "postgresql://..."}
)

connection = await client.connect(server_config)

# Discover tools
tools = await connection.list_tools()
print(f"Discovered {len(tools)} tools")

# Invoke tool
result = await connection.call_tool(
    name="query_database",
    arguments={"query": "SELECT * FROM users LIMIT 10"}
)
print(result)
```

#### 2.1.2 API Reference

**MCPClient**

```python
class MCPClient:
    """
    Main client for managing MCP server connections.
    """
    
    def __init__(self, config_path: str = "config/mcp_servers.json"):
        """
        Initialize MCP client with server configuration.
        
        Args:
            config_path: Path to MCP servers configuration file
        """
    
    async def connect(self, server_config: MCPServerConfig) -> MCPConnection:
        """
        Connect to an MCP server.
        
        Args:
            server_config: Server configuration
            
        Returns:
            MCPConnection instance
            
        Raises:
            MCPConnectionError: If connection fails
        """
    
    async def connect_all(self) -> Dict[str, MCPConnection]:
        """
        Connect to all configured MCP servers.
        
        Returns:
            Dictionary mapping server names to connections
        """
    
    async def disconnect(self, server_name: str):
        """
        Disconnect from an MCP server.
        
        Args:
            server_name: Name of server to disconnect
        """
    
    async def disconnect_all(self):
        """Disconnect from all servers."""
```

**MCPConnection**

```python
class MCPConnection:
    """
    Connection to a single MCP server.
    """
    
    async def list_tools(self) -> List[Tool]:
        """
        List all available tools from this server.
        
        Returns:
            List of Tool objects
            
        Raises:
            MCPError: If tool discovery fails
        """
    
    async def call_tool(
        self,
        name: str,
        arguments: Dict[str, Any],
        timeout: Optional[float] = None
    ) -> ToolResult:
        """
        Invoke a tool.
        
        Args:
            name: Tool name
            arguments: Tool arguments (must match tool schema)
            timeout: Optional timeout in seconds
            
        Returns:
            ToolResult with output and metadata
            
        Raises:
            ToolNotFoundError: If tool doesn't exist
            ToolInvocationError: If tool execution fails
            TimeoutError: If execution exceeds timeout
        """
    
    async def get_tool_schema(self, name: str) -> Dict[str, Any]:
        """
        Get schema for a specific tool.
        
        Args:
            name: Tool name
            
        Returns:
            Tool schema dictionary
            
        Raises:
            ToolNotFoundError: If tool doesn't exist
        """
    
    def is_connected(self) -> bool:
        """Check if connection is active."""
    
    async def ping(self) -> bool:
        """Ping server to check connectivity."""
```

**Tool**

```python
@dataclass
class Tool:
    """Represents an MCP tool."""
    name: str
    description: str
    input_schema: Dict[str, Any]
    server_name: str
    
    def validate_arguments(self, arguments: Dict[str, Any]) -> bool:
        """
        Validate arguments against tool schema.
        
        Args:
            arguments: Arguments to validate
            
        Returns:
            True if valid, False otherwise
        """
```

**ToolResult**

```python
@dataclass
class ToolResult:
    """Result from tool invocation."""
    content: List[Dict[str, Any]]  # Tool output content
    is_error: bool
    error_message: Optional[str]
    metadata: Dict[str, Any]
```

#### 2.1.3 Error Handling

```python
from mcp_client import (
    MCPClient,
    MCPConnectionError,
    ToolNotFoundError,
    ToolInvocationError,
    TimeoutError
)

client = MCPClient()

try:
    connection = await client.connect(server_config)
except MCPConnectionError as e:
    print(f"Failed to connect: {e}")
    # Handle connection failure

try:
    result = await connection.call_tool("query_database", {"query": "SELECT 1"})
    if result.is_error:
        print(f"Tool error: {result.error_message}")
except ToolNotFoundError:
    print("Tool not found")
except ToolInvocationError as e:
    print(f"Tool invocation failed: {e}")
except TimeoutError:
    print("Tool execution timed out")
```

#### 2.1.4 Connection Management

```python
# Automatic reconnection
client = MCPClient(auto_reconnect=True, max_retries=3)

# Connection pooling
client = MCPClient(max_connections=10)

# Health checks
async def check_server_health(connection: MCPConnection):
    if not await connection.ping():
        # Reconnect
        await client.reconnect(connection.server_name)
```

---

### 2.2 Node.js Wrapper

#### 2.2.1 Installation

```bash
npm install @modelcontextprotocol/sdk dotenv
```

#### 2.2.2 Basic Usage

```javascript
const { MCPClient, MCPServerConfig } = require('@mcp/client');

// Create client
const client = new MCPClient();

// Connect to server
const serverConfig = new MCPServerConfig({
    name: 'database_server',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-postgres'],
    env: { DATABASE_URL: 'postgresql://...' }
});

const connection = await client.connect(serverConfig);

// Discover tools
const tools = await connection.listTools();
console.log(`Discovered ${tools.length} tools`);

// Invoke tool
const result = await connection.callTool('query_database', {
    query: 'SELECT * FROM users LIMIT 10'
});
console.log(result);
```

#### 2.2.2 API Reference

**MCPClient**

```javascript
class MCPClient {
    /**
     * Initialize MCP client with server configuration.
     * @param {string} configPath - Path to MCP servers configuration file
     */
    constructor(configPath = 'config/mcp_servers.json') {}
    
    /**
     * Connect to an MCP server.
     * @param {MCPServerConfig} serverConfig - Server configuration
     * @returns {Promise<MCPConnection>} Connection instance
     * @throws {MCPConnectionError} If connection fails
     */
    async connect(serverConfig) {}
    
    /**
     * Connect to all configured MCP servers.
     * @returns {Promise<Object<string, MCPConnection>>} Map of server names to connections
     */
    async connectAll() {}
    
    /**
     * Disconnect from an MCP server.
     * @param {string} serverName - Name of server to disconnect
     */
    async disconnect(serverName) {}
    
    /**
     * Disconnect from all servers.
     */
    async disconnectAll() {}
}
```

**MCPConnection**

```javascript
class MCPConnection {
    /**
     * List all available tools from this server.
     * @returns {Promise<Array<Tool>>} List of Tool objects
     * @throws {MCPError} If tool discovery fails
     */
    async listTools() {}
    
    /**
     * Invoke a tool.
     * @param {string} name - Tool name
     * @param {Object} arguments - Tool arguments
     * @param {number} timeout - Optional timeout in milliseconds
     * @returns {Promise<ToolResult>} Tool result
     * @throws {ToolNotFoundError} If tool doesn't exist
     * @throws {ToolInvocationError} If tool execution fails
     * @throws {TimeoutError} If execution exceeds timeout
     */
    async callTool(name, arguments, timeout) {}
    
    /**
     * Get schema for a specific tool.
     * @param {string} name - Tool name
     * @returns {Promise<Object>} Tool schema
     * @throws {ToolNotFoundError} If tool doesn't exist
     */
    async getToolSchema(name) {}
    
    /**
     * Check if connection is active.
     * @returns {boolean}
     */
    isConnected() {}
    
    /**
     * Ping server to check connectivity.
     * @returns {Promise<boolean>}
     */
    async ping() {}
}
```

**Tool**

```javascript
class Tool {
    constructor(name, description, inputSchema, serverName) {
        this.name = name;
        this.description = description;
        this.inputSchema = inputSchema;
        this.serverName = serverName;
    }
    
    /**
     * Validate arguments against tool schema.
     * @param {Object} arguments - Arguments to validate
     * @returns {boolean} True if valid
     */
    validateArguments(arguments) {}
}
```

**ToolResult**

```javascript
class ToolResult {
    constructor(content, isError, errorMessage, metadata) {
        this.content = content;  // Array of content objects
        this.isError = isError;
        this.errorMessage = errorMessage;
        this.metadata = metadata;
    }
}
```

#### 2.2.3 Error Handling

```javascript
const {
    MCPClient,
    MCPConnectionError,
    ToolNotFoundError,
    ToolInvocationError,
    TimeoutError
} = require('@mcp/client');

const client = new MCPClient();

try {
    const connection = await client.connect(serverConfig);
} catch (error) {
    if (error instanceof MCPConnectionError) {
        console.error(`Failed to connect: ${error.message}`);
    }
}

try {
    const result = await connection.callTool('query_database', { query: 'SELECT 1' });
    if (result.isError) {
        console.error(`Tool error: ${result.errorMessage}`);
    }
} catch (error) {
    if (error instanceof ToolNotFoundError) {
        console.error('Tool not found');
    } else if (error instanceof ToolInvocationError) {
        console.error(`Tool invocation failed: ${error.message}`);
    } else if (error instanceof TimeoutError) {
        console.error('Tool execution timed out');
    }
}
```

---

## 4. Tool Discovery

### 3.1 Discovery Process

1. **Load Server Configuration**: Read `config/mcp_servers.json`
2. **Connect to Servers**: Establish connections to all configured servers
3. **List Tools**: Call `list_tools()` on each server
4. **Register Tools**: Store tools in `exp.mcp_tools` table
5. **Link to Variants**: Assign tools to variants via `exp.variant_tools`

### 3.2 Discovery Implementation

**Python:**

```python
async def discover_and_register_tools(client: MCPClient, db_connection):
    """
    Discover tools from all MCP servers and register in database.
    """
    connections = await client.connect_all()
    
    for server_name, connection in connections.items():
        try:
            tools = await connection.list_tools()
            
            for tool in tools:
                # Register tool in database
                await register_tool(
                    db_connection,
                    name=tool.name,
                    description=tool.description,
                    server_name=server_name,
                    tool_schema=tool.input_schema,
                    capabilities={}
                )
        except Exception as e:
            log_error(f"Failed to discover tools from {server_name}: {e}")
```

**Node.js:**

```javascript
async function discoverAndRegisterTools(client, dbConnection) {
    const connections = await client.connectAll();
    
    for (const [serverName, connection] of Object.entries(connections)) {
        try {
            const tools = await connection.listTools();
            
            for (const tool of tools) {
                // Register tool in database
                await registerTool(dbConnection, {
                    name: tool.name,
                    description: tool.description,
                    serverName: serverName,
                    toolSchema: tool.inputSchema,
                    capabilities: {}
                });
            }
        } catch (error) {
            console.error(`Failed to discover tools from ${serverName}:`, error);
        }
    }
}
```

### 3.3 Tool Registration

```python
async def register_tool(
    db_connection,
    name: str,
    description: str,
    server_name: str,
    tool_schema: Dict[str, Any],
    capabilities: Dict[str, Any]
):
    """
    Register a tool in the database.
    """
    query = """
        INSERT INTO exp.mcp_tools (name, description, server_name, tool_schema, capabilities, status)
        VALUES (%s, %s, %s, %s, %s, 'active')
        ON CONFLICT (server_name, name) 
        DO UPDATE SET
            description = EXCLUDED.description,
            tool_schema = EXCLUDED.tool_schema,
            capabilities = EXCLUDED.capabilities,
            updated_at = NOW()
        RETURNING id
    """
    
    result = await db_connection.execute(
        query,
        (name, description, server_name, json.dumps(tool_schema), json.dumps(capabilities))
    )
    
    return result[0]['id']
```

---

## 5. Tool Invocation Patterns

### 4.1 Basic Invocation

```python
# Simple tool call
result = await connection.call_tool(
    name="query_database",
    arguments={"query": "SELECT * FROM users LIMIT 10"}
)

if result.is_error:
    handle_error(result.error_message)
else:
    process_result(result.content)
```

### 4.2 With Retry Logic

```python
async def call_tool_with_retry(
    connection: MCPConnection,
    name: str,
    arguments: Dict[str, Any],
    max_retries: int = 3
) -> ToolResult:
    """
    Call tool with automatic retry on failure.
    """
    for attempt in range(max_retries):
        try:
            result = await connection.call_tool(name, arguments)
            if not result.is_error:
                return result
            
            # Retry on certain errors
            if attempt < max_retries - 1:
                await asyncio.sleep(2 ** attempt)  # Exponential backoff
        except (ToolInvocationError, TimeoutError) as e:
            if attempt == max_retries - 1:
                raise
            await asyncio.sleep(2 ** attempt)
    
    return result
```

### 4.3 Batch Invocation

```python
async def call_tools_batch(
    connection: MCPConnection,
    tool_calls: List[Tuple[str, Dict[str, Any]]]
) -> List[ToolResult]:
    """
    Call multiple tools concurrently.
    """
    tasks = [
        connection.call_tool(name, arguments)
        for name, arguments in tool_calls
    ]
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Handle exceptions
    processed_results = []
    for result in results:
        if isinstance(result, Exception):
            processed_results.append(ToolResult(
                content=[],
                is_error=True,
                error_message=str(result),
                metadata={}
            ))
        else:
            processed_results.append(result)
    
    return processed_results
```

---

## 6. Common MCP Server Examples

### 5.1 Database Server

**Configuration:**

```json
{
  "name": "database_server",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-postgres"],
  "env": {
    "DATABASE_URL": "postgresql://user:pass@localhost/dbname"
  }
}
```

**Usage:**

```python
connection = await client.connect(database_server_config)

# Query database
result = await connection.call_tool("query_database", {
    "query": "SELECT id, name FROM users WHERE active = true",
    "limit": 100
})

# Execute update
result = await connection.call_tool("execute_sql", {
    "query": "UPDATE users SET last_login = NOW() WHERE id = $1",
    "parameters": [user_id]
})
```

### 5.2 API Server

**Configuration:**

```json
{
  "name": "api_server",
  "command": "python",
  "args": ["-m", "mcp_server_api"],
  "env": {
    "API_BASE_URL": "https://api.example.com",
    "API_KEY": "${API_KEY}"
  }
}
```

**Usage:**

```python
connection = await client.connect(api_server_config)

# Make API call
result = await connection.call_tool("http_request", {
    "method": "GET",
    "url": "/users",
    "headers": {"Authorization": "Bearer token"}
})
```

### 5.3 File System Server

**Configuration:**

```json
{
  "name": "filesystem_server",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem"],
  "env": {
    "ALLOWED_DIRECTORIES": "/data:/tmp"
  }
}
```

**Usage:**

```python
connection = await client.connect(filesystem_server_config)

# Read file
result = await connection.call_tool("read_file", {
    "path": "/data/config.json"
})

# Write file
result = await connection.call_tool("write_file", {
    "path": "/tmp/output.json",
    "content": json.dumps(data)
})
```

---

## 7. Connection Management

### 6.1 Connection Lifecycle

```python
# Initialize client
client = MCPClient()

# Connect to servers
connections = await client.connect_all()

# Use connections
for server_name, connection in connections.items():
    tools = await connection.list_tools()
    # Process tools

# Cleanup
await client.disconnect_all()
```

### 6.2 Health Monitoring

```python
async def monitor_connections(client: MCPClient):
    """
    Monitor connection health and reconnect if needed.
    """
    while True:
        for server_name in client.get_connected_servers():
            connection = client.get_connection(server_name)
            
            if not await connection.ping():
                log_warning(f"Connection to {server_name} lost, reconnecting...")
                await client.reconnect(server_name)
        
        await asyncio.sleep(60)  # Check every minute
```

### 6.3 Connection Pooling

```python
class MCPConnectionPool:
    """
    Pool of MCP connections for concurrent access.
    """
    
    def __init__(self, max_connections: int = 10):
        self.max_connections = max_connections
        self.pool = asyncio.Queue(maxsize=max_connections)
    
    async def get_connection(self, server_name: str) -> MCPConnection:
        """Get connection from pool."""
        if not self.pool.empty():
            return await self.pool.get()
        
        # Create new connection
        return await self.client.connect(server_name)
    
    async def return_connection(self, connection: MCPConnection):
        """Return connection to pool."""
        await self.pool.put(connection)
```

---

## 8. Error Handling

### 7.1 Error Types

| Error Type | Description | Recovery Strategy |
|------------|------------|-------------------|
| `MCPConnectionError` | Failed to connect to server | Retry with exponential backoff |
| `ToolNotFoundError` | Tool doesn't exist | Check tool name, verify server connection |
| `ToolInvocationError` | Tool execution failed | Check arguments, verify server state |
| `TimeoutError` | Tool execution timed out | Increase timeout, check server load |
| `SchemaValidationError` | Invalid tool arguments | Validate arguments before calling |

### 7.2 Error Handling Best Practices

```python
async def safe_tool_call(
    connection: MCPConnection,
    name: str,
    arguments: Dict[str, Any]
) -> Optional[ToolResult]:
    """
    Safely call a tool with comprehensive error handling.
    """
    try:
        # Validate arguments first
        tool_schema = await connection.get_tool_schema(name)
        if not validate_arguments(arguments, tool_schema):
            log_error(f"Invalid arguments for tool {name}")
            return None
        
        # Call tool with timeout
        result = await connection.call_tool(name, arguments, timeout=30)
        
        if result.is_error:
            log_error(f"Tool {name} returned error: {result.error_message}")
            return None
        
        return result
        
    except ToolNotFoundError:
        log_error(f"Tool {name} not found")
        return None
    except ToolInvocationError as e:
        log_error(f"Tool invocation failed: {e}")
        # Retry logic could go here
        return None
    except TimeoutError:
        log_error(f"Tool {name} timed out")
        return None
    except Exception as e:
        log_error(f"Unexpected error calling tool {name}: {e}")
        return None
```

---

## 9. Integration with Flow Orchestrator

### 8.1 Tool Discovery in Flows

```python
async def get_tools_for_variant(variant_id: str, db_connection) -> List[Tool]:
    """
    Get tools available for a variant.
    """
    query = """
        SELECT t.*, vt.priority, vt.enabled
        FROM exp.mcp_tools t
        INNER JOIN exp.variant_tools vt ON t.id = vt.tool_id
        WHERE vt.variant_id = %s
          AND vt.enabled = true
          AND t.status = 'active'
        ORDER BY vt.priority ASC, t.name ASC
    """
    
    rows = await db_connection.execute(query, (variant_id,))
    
    return [
        Tool(
            name=row['name'],
            description=row['description'],
            input_schema=row['tool_schema'],
            server_name=row['server_name']
        )
        for row in rows
    ]
```

### 8.2 Tool Invocation in Actions

```python
# In flow action execution
if action['type'] == 'call_api':
    # Get MCP connection for server
    connection = mcp_client.get_connection(action['server_name'])
    
    # Call tool
    result = await connection.call_tool(
        name=action['tool_name'],
        arguments=action['arguments']
    )
    
    # Store result in conversation data
    conversation_data[action['result_field']] = result.content
```

---

## 9. Related Documentation

| Document | Purpose |
|----------|---------|
| [data-model.md](data-model.md) | Database schema (section 5: MCP Tool Registry) |
| [../config/mcp_servers.example.json](../config/mcp_servers.example.json) | MCP server configuration examples |
| [../services/flow-orchestrator/API_SPEC.md](../services/flow-orchestrator/API_SPEC.md) | Flow Orchestrator API |

---

## After Completing This Document

You will understand:
- How to use MCP client wrappers in Python and Node.js
- How to discover and register tools from MCP servers
- How to invoke tools with proper error handling
- How to manage MCP server connections
- How to integrate MCP tools into conversation flows

**Next Step**: Configure MCP servers using `config/mcp_servers.example.json`
