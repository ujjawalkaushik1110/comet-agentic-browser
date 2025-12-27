# Quick Reference Guide - Comet Agentic Browser

## Installation

```bash
pip install -r requirements.txt
playwright install chromium
ollama pull mistral
```

## Quick Start

```python
import asyncio
from agent.core import browse

result = asyncio.run(browse("Go to example.com and describe it"))
print(result['result'])
```

## Common Usage Patterns

### 1. Simple Task
```python
from agent.core import browse

result = await browse("Navigate to github.com and tell me what you see")
```

### 2. Context Manager
```python
from agent.core import AgenticBrowser

async with AgenticBrowser(model="mistral") as agent:
    result = await agent.run("Your task here")
    print(result['result'])
```

### 3. Multiple Tasks
```python
async with AgenticBrowser(model="mistral") as agent:
    task1 = await agent.run("Go to example.com")
    task2 = await agent.run("Go to github.com")
```

### 4. Custom Configuration
```python
agent = AgenticBrowser(
    model="mistral",
    headless=True,
    max_iterations=20,
    base_url="http://localhost:11434",
    api_type="ollama"
)

async with agent:
    result = await agent.run("Complex task...")
```

## Task Examples

### Information Gathering
```python
await browse("Go to news.ycombinator.com and tell me the top story")
```

### Content Extraction
```python
await browse("Navigate to example.com and read the main heading")
```

### Screenshot
```python
await browse("Go to github.com and take a screenshot called 'github.png'")
```

### Multi-Step
```python
await browse("""
1. Go to example.com
2. Read the page content
3. Take a screenshot
4. Summarize what you found
""")
```

## Configuration Options

### AgenticBrowser Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | str | "mistral" | LLM model name |
| `headless` | bool | True | Run browser headless |
| `max_iterations` | int | 15 | Max agent loops |
| `base_url` | str | "http://localhost:11434" | LLM API URL |
| `api_type` | str | "ollama" | API type |
| `api_key` | str | None | API key |

### BrowserController Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `headless` | bool | True | Headless mode |
| `viewport_width` | int | 1280 | Viewport width |
| `viewport_height` | int | 720 | Viewport height |
| `timeout` | int | 30000 | Timeout (ms) |
| `screenshot_dir` | str | "screenshots" | Screenshot directory |

## API Reference

### AgenticBrowser

```python
class AgenticBrowser:
    async def run(goal: str) -> Dict[str, Any]
    async def start() -> None
    async def close() -> None
```

### Result Dictionary

```python
{
    "success": bool,           # Whether task completed successfully
    "result": str,            # Final answer/result
    "iterations": int,        # Number of iterations used
    "conversation_history": List[Dict]  # Full conversation
}
```

### LLMClient

```python
class LLMClient:
    async def chat_completion(
        messages: List[Dict],
        tools: Optional[List[Dict]] = None,
        tool_choice: str = "auto"
    ) -> Dict[str, Any]
```

### BrowserController

```python
class BrowserController:
    async def navigate(url: str) -> Dict[str, Any]
    async def get_content(selector: Optional[str] = None) -> Dict[str, Any]
    async def screenshot(filename: str, selector: Optional[str] = None, 
                        full_page: bool = False) -> str
    async def get_page_info() -> Dict[str, Any]
```

## Error Handling

```python
try:
    async with AgenticBrowser(model="mistral") as agent:
        result = await agent.run("Your task")
except RuntimeError as e:
    print(f"Runtime error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

## Debugging

### Enable Logging
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Visual Debugging
```python
agent = AgenticBrowser(model="mistral", headless=False)
```

### Inspect History
```python
result = await agent.run("Task")
for msg in result['conversation_history']:
    print(f"{msg['role']}: {msg.get('content', '')[:100]}")
```

## Command Line

```bash
# Default task
python main.py

# Custom task
python main.py "Go to example.com and describe it"

# Run examples
python example.py

# Run tests
python test.py
```

## Environment Variables

```bash
# Ollama settings
export OLLAMA_HOST="http://localhost:11434"

# OpenAI settings (if using OpenAI)
export OPENAI_API_KEY="sk-..."
export OPENAI_BASE_URL="https://api.openai.com"
```

## Tips & Best Practices

1. ✅ **Use context managers** for automatic cleanup
2. ✅ **Be specific in tasks** - include full URLs
3. ✅ **Use headless mode** in production
4. ✅ **Handle exceptions** properly
5. ❌ **Don't** use very long tasks in one go
6. ❌ **Don't** forget to start Ollama before running

## Troubleshooting Quick Fixes

| Problem | Solution |
|---------|----------|
| "Connection refused" | Start Ollama: `ollama serve` |
| "Browser not started" | Use context manager or call `await agent.start()` |
| "Model not found" | Pull model: `ollama pull mistral` |
| "Playwright not installed" | Run: `playwright install chromium` |
| "Max iterations" | Increase `max_iterations` or simplify task |

## Performance Tips

- Use local LLMs (Ollama) for faster responses
- Enable headless mode for better performance
- Reduce max_iterations for simple tasks
- Pre-warm the browser for multiple tasks
- Limit content reading to avoid token overload

## File Locations

```
screenshots/        # All screenshots saved here
agent/core.py      # Main agent logic
browser/automation.py  # Browser controller
main.py           # CLI entry point
example.py        # Usage examples
test.py          # Test suite
```

## Useful Snippets

### Check Ollama Status
```bash
curl http://localhost:11434/api/tags
```

### List Available Models
```bash
ollama list
```

### Monitor Browser Activity
```python
# Set headless=False to see what the browser is doing
agent = AgenticBrowser(model="mistral", headless=False)
```

### Save Conversation
```python
import json

result = await agent.run("Task")
with open("conversation.json", "w") as f:
    json.dump(result['conversation_history'], f, indent=2)
```
