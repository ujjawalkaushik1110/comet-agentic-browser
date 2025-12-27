# 🤖 Comet Agentic Browser

An intelligent, AI-powered web browser that uses Large Language Models (LLMs) to autonomously navigate and interact with websites. Built with Python, Playwright, and Ollama.

## ✨ Features

- **Autonomous Web Browsing**: Uses LLMs to understand goals and navigate websites intelligently
- **Perception-Reasoning-Action Loop**: Implements a sophisticated agent architecture
- **Multiple LLM Support**: Works with Ollama (local), OpenAI, and other compatible APIs
- **Tool Calling**: Structured tool use for navigation, content reading, and screenshots
- **Context Management**: Maintains conversation history for coherent multi-step tasks
- **Async/Await**: Fully asynchronous for efficient execution

## 🏗️ Architecture

The browser implements a classic agent architecture with three phases:

1. **Perception**: Gathers current state (URL, page title, readiness)
2. **Reasoning**: LLM decides the next action based on goal and context
3. **Action**: Executes browser tools (navigate, read_page, screenshot, complete)

## 📦 Installation

### Prerequisites

- Python 3.8+
- [Ollama](https://ollama.ai/) (for local LLM support)

### Setup

```bash
# Clone the repository
git clone https://github.com/ujjawalkaushik1110/comet-agentic-browser.git
cd comet-agentic-browser

# Install dependencies
pip install -r requirements.txt

# Install Playwright browsers
playwright install chromium

# Start Ollama with Mistral model
ollama pull mistral
ollama serve
```

## 🚀 Usage

### Basic Usage

```python
import asyncio
from agent.core import browse

# Simple one-liner
result = asyncio.run(browse("Go to example.com and tell me what you see"))
print(result['result'])
```

### Using Context Manager

```python
import asyncio
from agent.core import AgenticBrowser

async def main():
    async with AgenticBrowser(model="mistral") as agent:
        result = await agent.run("Navigate to github.com and describe the page")
        print(result['result'])

asyncio.run(main())
```

### Command Line

```bash
# Using default task
python main.py

# With custom task
python main.py "Go to perplexity.ai and summarize what the site is about"
```

### Advanced Configuration

```python
from agent.core import AgenticBrowser

agent = AgenticBrowser(
    model="mistral",           # LLM model name
    headless=True,            # Run browser in headless mode
    max_iterations=15,        # Max reasoning loops
    base_url="http://localhost:11434",  # Ollama API URL
    api_type="ollama",        # API type: "ollama" or "openai"
    api_key=None              # API key for remote services
)

await agent.start()
result = await agent.run("Your task here")
await agent.close()
```

## 🛠️ Available Tools

The agent has access to these tools:

1. **navigate(url)**: Navigate to a URL
2. **read_page(selector=None)**: Read page content (full page or specific selector)
3. **screenshot(filename, selector=None, full_page=False)**: Take screenshots
4. **complete(answer)**: Mark task as complete with final answer

## 📁 Project Structure

```
comet-agentic-browser/
├── agent/
│   ├── __init__.py
│   └── core.py              # Main AgenticBrowser class and LLMClient
├── browser/
│   ├── __init__.py
│   └── automation.py        # Playwright browser controller
├── screenshots/             # Screenshot output directory
├── main.py                  # CLI entry point
├── example.py              # Usage examples
├── requirements.txt        # Python dependencies
└── README.md              # This file
```

## 🧩 How It Works

### 1. Initialize the Agent

```python
agent = AgenticBrowser(model="mistral", headless=True)
await agent.start()
```

### 2. Define Your Goal

```python
goal = "Go to example.com, read the content, and take a screenshot"
```

### 3. Run the Agent

The agent will:
- Understand the goal
- Break it into steps
- Use tools (navigate, read_page, screenshot)
- Reason about what to do next
- Complete the task

```python
result = await agent.run(goal)
```

### 4. Get the Result

```python
print(f"Success: {result['success']}")
print(f"Answer: {result['result']}")
print(f"Iterations: {result['iterations']}")
```

## 🔧 Configuration

### Using Different LLMs

#### Ollama (Default)
```python
agent = AgenticBrowser(
    model="mistral",
    api_type="ollama",
    base_url="http://localhost:11434"
)
```

#### OpenAI
```python
agent = AgenticBrowser(
    model="gpt-4",
    api_type="openai",
    base_url="https://api.openai.com",
    api_key="your-api-key"
)
```

### Browser Settings

Modify `browser/automation.py` for custom browser settings:
- Viewport size
- Timeout durations
- Screenshot directory
- User agent

## 📝 Examples

See [example.py](example.py) for complete examples:

```python
# Example 1: Simple task
result = await browse("Go to httpbin.org and read the page")

# Example 2: Multi-step task
async with AgenticBrowser(model="mistral") as agent:
    result = await agent.run("""
        1. Go to example.com
        2. Read the page content
        3. Take a screenshot named 'example.png'
        4. Tell me what you found
    """)
```

## 🐛 Troubleshooting

### Ollama Connection Error
```bash
# Make sure Ollama is running
ollama serve

# Pull the model if not already downloaded
ollama pull mistral
```

### Browser Issues
```bash
# Reinstall Playwright browsers
playwright install --force chromium
```

### Module Import Errors
```bash
# Install all dependencies
pip install -r requirements.txt
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Playwright](https://playwright.dev/)
- LLM support via [Ollama](https://ollama.ai/)
- Inspired by agent-based AI architectures

## 🔮 Future Enhancements

- [ ] More browser tools (click, fill forms, scroll)
- [ ] Multi-page navigation
- [ ] Session persistence
- [ ] Visual understanding with vision models
- [ ] Parallel task execution
- [ ] Web scraping capabilities
- [ ] RESTful API interface

## 📧 Contact

For questions or suggestions, please open an issue on GitHub.
