# Comet Agentic Browser - Technical Documentation

## Overview

The Comet Agentic Browser is an autonomous web browsing agent that uses Large Language Models (LLMs) to understand goals and navigate websites intelligently. It implements a perception-reasoning-action loop architecture.

## Architecture

### Core Components

#### 1. **AgenticBrowser** (`agent/core.py`)
The main orchestrator that implements the agent loop.

**Key Responsibilities:**
- Initialize and manage browser and LLM clients
- Run the perception-reasoning-action loop
- Maintain conversation history
- Coordinate tool execution

**Key Methods:**
- `run(goal)`: Execute the main agent loop
- `_perceive()`: Gather current state information
- `_reason(perception)`: Use LLM to decide next action
- `_act(action_decision)`: Execute the decided tool
- Tool methods: `_tool_navigate()`, `_tool_read_page()`, `_tool_screenshot()`

#### 2. **LLMClient** (`agent/core.py`)
Handles communication with language models.

**Supported APIs:**
- Ollama (local models)
- OpenAI-compatible APIs

**Key Methods:**
- `chat_completion(messages, tools, tool_choice)`: Get LLM response
- `_ollama_completion()`: Ollama-specific implementation
- `_openai_completion()`: OpenAI-specific implementation
- `_create_tool_prompt()`: Format tools for the LLM
- `_parse_tool_calls_from_text()`: Extract tool calls from response

#### 3. **BrowserController** (`browser/automation.py`)
Manages the Playwright browser instance.

**Key Methods:**
- `start()`: Initialize browser
- `close()`: Clean up browser
- `navigate(url)`: Navigate to URL
- `get_content(selector)`: Extract page content
- `screenshot(filename, selector, full_page)`: Take screenshots
- `get_page_info()`: Get page metadata
- Additional methods: `click()`, `fill()`, `evaluate()`, `wait_for_selector()`

## Agent Loop Flow

```
1. INITIALIZATION
   ├─ Start browser (Playwright Chromium)
   ├─ Initialize LLM client
   └─ Set up conversation history

2. PERCEPTION (gather state)
   ├─ Get current URL
   ├─ Get page title
   ├─ Get page ready state
   └─ Return perception dict

3. REASONING (LLM decides)
   ├─ Add perception to context
   ├─ Call LLM with tools
   ├─ Parse response
   └─ Return action decision

4. ACTION (execute tool)
   ├─ Extract tool name and arguments
   ├─ Execute tool method
   ├─ Capture result
   └─ Add to conversation history

5. ITERATION
   ├─ If complete → return result
   ├─ If max iterations → return partial
   └─ Else → goto step 2

6. CLEANUP
   └─ Close browser
```

## Tool System

### Available Tools

#### 1. navigate
```json
{
  "name": "navigate",
  "description": "Navigate to a specific URL",
  "parameters": {
    "url": "string (required)"
  }
}
```

#### 2. read_page
```json
{
  "name": "read_page",
  "description": "Read page content",
  "parameters": {
    "selector": "string (optional)"
  }
}
```

#### 3. screenshot
```json
{
  "name": "screenshot",
  "description": "Take a screenshot",
  "parameters": {
    "filename": "string (required)",
    "selector": "string (optional)",
    "full_page": "boolean (optional)"
  }
}
```

#### 4. complete
```json
{
  "name": "complete",
  "description": "Mark task as complete",
  "parameters": {
    "answer": "string (required)"
  }
}
```

### Tool Execution Flow

1. LLM generates tool call (JSON format)
2. Parser extracts tool name and arguments
3. `_act()` method routes to appropriate tool handler
4. Tool handler executes browser action
5. Result wrapped in `ToolResult` dataclass
6. Result added to conversation history

## LLM Integration

### Ollama Integration

For local models (default):

```python
client = LLMClient(
    model="mistral",
    api_type="ollama",
    base_url="http://localhost:11434"
)
```

**Message Format:**
- Cleaned messages (removes tool role messages)
- Tool definitions embedded in system prompt
- Tool calls parsed from JSON in response text

### OpenAI Integration

For OpenAI-compatible APIs:

```python
client = LLMClient(
    model="gpt-4",
    api_type="openai",
    base_url="https://api.openai.com",
    api_key="sk-..."
)
```

**Message Format:**
- Standard OpenAI message format
- Native tool calling support
- Tool calls in structured format

## Error Handling

### Browser Errors
- Navigation failures → retry or report
- Element not found → error result
- Timeout → configurable timeout settings

### LLM Errors
- Connection failures → raise exception
- Invalid tool calls → parse error handling
- No tool call → treat as completion

### Agent Errors
- Max iterations reached → partial result
- Tool execution failure → error in ToolResult
- Unexpected exceptions → logged and propagated

## Configuration

### Browser Settings

In `BrowserController`:
```python
BrowserController(
    headless=True,           # Headless mode
    viewport_width=1280,     # Browser width
    viewport_height=720,     # Browser height
    timeout=30000,          # Default timeout (ms)
    screenshot_dir="screenshots"  # Screenshot directory
)
```

### Agent Settings

In `AgenticBrowser`:
```python
AgenticBrowser(
    model="mistral",        # LLM model
    headless=True,         # Browser headless
    max_iterations=15,     # Max loops
    base_url="...",        # LLM API URL
    api_type="ollama",     # LLM API type
    api_key=None          # API key
)
```

## Usage Patterns

### Pattern 1: Context Manager (Recommended)
```python
async with AgenticBrowser(model="mistral") as agent:
    result = await agent.run("Your goal here")
```

### Pattern 2: Manual Lifecycle
```python
agent = AgenticBrowser(model="mistral")
await agent.start()
try:
    result = await agent.run("Your goal")
finally:
    await agent.close()
```

### Pattern 3: Convenience Function
```python
result = await browse("Your goal", model="mistral")
```

## Performance Considerations

1. **Browser Startup**: ~1-2 seconds
2. **LLM Response**: 1-5 seconds per iteration
3. **Page Navigation**: 1-3 seconds per page
4. **Total Time**: Typically 10-30 seconds for simple tasks

### Optimization Tips

- Use `headless=True` for faster execution
- Reduce `max_iterations` for simpler tasks
- Use local LLMs (Ollama) to avoid API latency
- Pre-warm browser if running multiple tasks

## Debugging

### Enable Debug Logging
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Inspect Conversation History
```python
result = await agent.run("Your goal")
for msg in result['conversation_history']:
    print(msg)
```

### Browser Inspection
Set `headless=False` to see browser actions:
```python
agent = AgenticBrowser(model="mistral", headless=False)
```

## Extension Points

### Adding New Tools

1. Define tool in `TOOLS` array:
```python
{
    "name": "my_tool",
    "description": "...",
    "parameters": {...}
}
```

2. Implement tool method:
```python
async def _tool_my_tool(self, args):
    # Implementation
    return result
```

3. Add routing in `_act()`:
```python
elif tool_name == "my_tool":
    result = await self._tool_my_tool(tool_args)
```

### Custom LLM Backend

Extend `LLMClient`:
```python
async def _custom_completion(self, messages, tools, tool_choice):
    # Your implementation
    return {"content": "...", "tool_calls": [...]}
```

## Testing

Run the test suite:
```bash
python test.py
```

Tests include:
- LLM client connectivity
- Browser controller functionality
- Tool call parsing
- Full integration test

## Troubleshooting

### Common Issues

**Issue**: "Browser not started"
- **Solution**: Call `await agent.start()` or use context manager

**Issue**: "Ollama API error"
- **Solution**: Ensure Ollama is running: `ollama serve`

**Issue**: "Max iterations reached"
- **Solution**: Increase `max_iterations` or simplify task

**Issue**: "Failed to parse tool call"
- **Solution**: Improve system prompt or use better model

## Best Practices

1. **Use context managers** for automatic cleanup
2. **Limit task complexity** for better success rates
3. **Provide specific URLs** in tasks
4. **Monitor iterations** to detect loops
5. **Use headless mode** in production
6. **Handle exceptions** at the application level
7. **Truncate long content** to avoid token limits

## Future Enhancements

- [ ] Click and form interaction tools
- [ ] Multi-page navigation with memory
- [ ] Visual understanding (screenshots → vision models)
- [ ] Session persistence and caching
- [ ] Parallel browser instances
- [ ] Web scraping mode
- [ ] API endpoint for HTTP access
