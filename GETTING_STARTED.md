# Getting Started with Comet Agentic Browser

## Quick Setup (5 minutes)

### Step 1: Install Dependencies
```bash
# Install Python dependencies
pip install -r requirements.txt

# Install Playwright browsers
playwright install chromium
```

### Step 2: Install and Start Ollama
```bash
# Install Ollama (if not already installed)
# Visit https://ollama.ai/ for installation instructions

# Pull the Mistral model
ollama pull mistral

# Start Ollama server (in a separate terminal)
ollama serve
```

### Step 3: Run Your First Task
```bash
# Run the default example
python main.py

# Or with a custom task
python main.py "Go to github.com and describe what you see"
```

## Your First Script

Create a file called `my_task.py`:

```python
import asyncio
from agent.core import browse

async def main():
    result = await browse(
        goal="Go to example.com and tell me what's on the page",
        model="mistral",
        headless=True
    )
    
    print("Success:", result['success'])
    print("Result:", result['result'])
    print("Iterations:", result['iterations'])

if __name__ == "__main__":
    asyncio.run(main())
```

Run it:
```bash
python my_task.py
```

## Common First Tasks

### 1. Visit a Website
```python
result = await browse("Go to example.com and describe it")
```

### 2. Read Content
```python
result = await browse("Navigate to news.ycombinator.com and tell me the top story")
```

### 3. Take Screenshot
```python
result = await browse("Go to github.com and take a screenshot named 'github.png'")
```

### 4. Multi-Step Task
```python
result = await browse("""
1. Navigate to httpbin.org
2. Read the page content
3. Tell me what services it provides
""")
```

## Verify Installation

Run the test suite to make sure everything works:
```bash
python test.py
```

You should see:
```
✅ LLM Client: PASS
✅ Browser: PASS
✅ Tool Parsing: PASS
✅ Integration: PASS
```

## Troubleshooting

### "Connection refused" error
**Problem**: Ollama isn't running
**Solution**: 
```bash
ollama serve
```

### "Model not found" error
**Problem**: Mistral model not downloaded
**Solution**:
```bash
ollama pull mistral
```

### "Playwright not found" error
**Problem**: Browser not installed
**Solution**:
```bash
playwright install chromium
```

### "aiohttp not found" error
**Problem**: Dependencies not installed
**Solution**:
```bash
pip install -r requirements.txt
```

## Next Steps

1. ✅ Read [README_NEW.md](README_NEW.md) for complete documentation
2. ✅ Check [QUICKREF.md](QUICKREF.md) for common patterns
3. ✅ Review [example.py](example.py) for more examples
4. ✅ See [TECHNICAL_DOCS.md](TECHNICAL_DOCS.md) for advanced usage

## Using Different LLMs

### Local Models (via Ollama)
```python
# Default - Mistral
agent = AgenticBrowser(model="mistral")

# Other Ollama models
agent = AgenticBrowser(model="llama2")
agent = AgenticBrowser(model="codellama")
```

### OpenAI
```python
agent = AgenticBrowser(
    model="gpt-4",
    api_type="openai",
    base_url="https://api.openai.com",
    api_key="sk-your-key-here"
)
```

## Example Output

When you run a task, you'll see:
```
🎯 Starting Agentic Browser with goal: Go to example.com and describe it
============================================================
Iteration 1/15
============================================================
📊 Perception: {'current_url': None, 'iteration': 0}
🧠 Reasoning: tool_call
⚙️  Executing tool: navigate with args: {'url': 'https://example.com'}
✅ Navigated to: https://example.com
============================================================
Iteration 2/15
============================================================
📊 Perception: {'current_url': 'https://example.com', 'page_title': 'Example Domain', ...}
🧠 Reasoning: tool_call
⚙️  Executing tool: read_page with args: {}
📄 Read page: Example Domain (length: 1234)
============================================================
Iteration 3/15
============================================================
✅ Agent has completed the task

📊 FINAL RESULT
============================================================
✅ Success: True
🔄 Iterations: 3
📝 Result: The page is Example Domain, which demonstrates...
============================================================
```

## Configuration Tips

### For Development
```python
agent = AgenticBrowser(
    model="mistral",
    headless=False,  # See what the browser does
    max_iterations=10
)
```

### For Production
```python
agent = AgenticBrowser(
    model="mistral",
    headless=True,  # Faster execution
    max_iterations=20  # Allow more complex tasks
)
```

## Best Practices

1. **Start with simple tasks** to understand how it works
2. **Use headless=False** when debugging
3. **Monitor iterations** to detect if agent is stuck
4. **Be specific** in your task descriptions
5. **Include full URLs** (with https://)

## Getting Help

- Check the documentation files
- Run the test suite to verify setup
- Look at examples in [example.py](example.py)
- Check logs for detailed execution info

## What's Possible?

✅ Navigate to any website
✅ Read page content
✅ Take screenshots
✅ Extract specific information
✅ Multi-step workflows
✅ Information gathering
✅ Content analysis

## Limitations

❌ Cannot interact with forms (yet)
❌ Cannot click buttons (yet)
❌ Cannot handle complex JavaScript interactions
❌ Limited to text-based understanding (no vision)

## Have Fun! 🚀

The agentic browser is ready to explore the web autonomously. Start with simple tasks and work your way up to more complex workflows.

For more advanced usage, check out the other documentation files!
