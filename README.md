# Comet Agentic Browser

🤖 An open-source AI agentic browser with Chromium and local LLMs (Llama 2, Mistral). Autonomous web automation without API costs. Built for GitHub Education.

## Features

✅ **100% Open Source** - No proprietary APIs or cloud dependencies  
✅ **Local LLM Integration** - Run Llama 2 or Mistral locally via Ollama  
✅ **Chromium Automation** - Headless browser control with Playwright  
✅ **Agentic Loop** - Perception → Reasoning → Action workflow  
✅ **Free on GitHub Codespaces** - 60 hours/month with Student Pack  
✅ **Tool-Use Capabilities** - Navigate, read pages, fill forms, take screenshots  
✅ **No API Costs** - Everything runs locally or self-hosted  

## Tech Stack

| Component | Technology | Why |
|-----------|-----------|-----|
| **LLM** | Ollama + Llama 2/Mistral | Free, local, no API costs |
| **Browser** | Chromium + Playwright | Open-source, lightweight |
| **Agent Framework** | LangChain | Open-source orchestration |
| **Runtime** | Python 3.10+ | Fast, well-documented |
| **API** | FastAPI | Async, modern framework |
| **Deployment** | Docker + GitHub Codespaces | Containerized, portable |

## Quick Start

### Prerequisites

- Python 3.10+
- 8GB RAM minimum (16GB recommended)
- Ollama installed

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/comet-agentic-browser.git
cd comet-agentic-browser

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate

# Install dependencies
pip install -r requirements.txt

# Start Ollama server
ollama serve

# In another terminal, pull Mistral model
ollama pull mistral:7b
```

### Usage

```python
from agent.core import AgenticBrowser

# Initialize the browser agent
agent = AgenticBrowser(model="mistral")

# Run a task
result = agent.run("Go to GitHub and search for 'open source' repositories")
print(result)
```

## Project Structure

```
comet-agentic-browser/
├── agent/
│   ├── core.py           # Agent loop implementation
│   ├── tools.py          # Tool definitions for browser
│   └── prompts.py        # System prompts & instructions
├── browser/
│   ├── automation.py     # Chromium/Playwright wrapper
│   ├── reader.py         # Page content extraction
│   └── screenshots.py    # Screenshot handling
├── llm/
│   ├── ollama_client.py  # Ollama integration
│   └── prompting.py      # LLM communication
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── main.py              # Entry point
└── README.md
```

## Open Source LLM Options

### Mistral 7B (Recommended for Codespaces)
- **Size**: 7B parameters
- **Speed**: ⚡⚡⚡ Very fast
- **Quality**: ⭐⭐⭐⭐ Excellent
- **Memory**: ~16GB
- **Best for**: Quick inference, resource-limited environments

### Llama 2 13B
- **Size**: 13B parameters
- **Speed**: ⚡⚡ Moderate
- **Quality**: ⭐⭐⭐⭐⭐ Outstanding
- **Memory**: ~24GB
- **Best for**: High-quality reasoning, complex tasks

### Zephyr 7B
- **Size**: 7B parameters
- **Speed**: ⚡⚡⚡ Very fast
- **Quality**: ⭐⭐⭐⭐ Excellent
- **Memory**: ~16GB
- **Best for**: Instruction following, chat tasks

## GitHub Student Benefits

This project leverages the GitHub Student Developer Pack:

- **GitHub Codespaces**: 60 free hours/month for development
- **GitHub Copilot Pro**: Free while you're a student
- **DigitalOcean**: $200 credit for production deployment
- **Microsoft Azure**: $100 credit + 25+ free services
- **MongoDB Atlas**: $50 in credits

[Claim your Student Pack](https://education.github.com/pack)

## Getting Started with Codespaces

1. Fork this repository
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait for the environment to build
4. In the terminal:
   ```bash
   pip install -r requirements.txt
   ollama serve  # Start LLM server
   ```
5. In another terminal:
   ```bash
   python main.py
   ```

## API Endpoints

```bash
# Start the API server
python -m uvicorn api:app --reload
```

### POST /task
Run an agentic task

```json
{
  "instruction": "Navigate to GitHub and search for Python repositories",
  "max_iterations": 10
}
```

### GET /task/{task_id}
Get task status and results

### POST /browser/screenshot
Capture current page screenshot

## Architecture

```
┌─────────────────────────────────┐
│   Natural Language Task         │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Ollama LLM (Local)             │
│  - Mistral/Llama/Zephyr         │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Agentic Loop                   │
│  1. Read page content           │
│  2. LLM decides next action     │
│  3. Execute browser tools       │
│  4. Repeat until task complete  │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Browser Automation Tools       │
│  - navigate() - goto URL        │
│  - read_page() - extract text   │
│  - find() - locate elements     │
│  - screenshot() - capture page  │
│  - form_input() - fill forms    │
│  - click() - interact with page │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│  Chromium Browser               │
│  Headless + JavaScript support  │
└─────────────────────────────────┘
```

## Examples

### Example 1: Search GitHub

```python
task = "Search GitHub for 'machine learning' repositories and list the top 3"
result = agent.run(task)
```

### Example 2: Fill Form

```python
task = "Go to example.com/form and fill out with name='John' and email='john@example.com'"
result = agent.run(task)
```

### Example 3: Data Extraction

```python
task = "Visit news.ycombinator.com and extract the titles of top 10 stories"
result = agent.run(task)
```

## Deployment

### Local Development

```bash
docker-compose up
```

### DigitalOcean (with $200 student credit)

```bash
docker build -t comet-browser .
docker push your-registry/comet-browser:latest
# Deploy to DigitalOcean App Platform
```

### Microsoft Azure (with $100 student credit)

```bash
az containerapp create --resource-group myResourceGroup \\
  --name comet-browser \\
  --image your-registry/comet-browser:latest
```

## Security & Privacy

- ✅ All processing happens locally (no data sent to external APIs)
- ✅ Browser history is not logged
- ✅ Supports headless mode (no GUI)
- ✅ Can run on private networks
- ✅ Open source code for security audits

## Troubleshooting

### Ollama not connecting

```bash
# Make sure Ollama is running
ollama serve

# Test connection
curl http://localhost:11434/api/tags
```

### Out of memory errors

- Use smaller model: `mistral` instead of `llama2:13b`
- Increase swap space
- Run on machine with 16GB+ RAM

### Playwright issues

```bash
# Install browser binaries
python -m playwright install chromium
```

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Roadmap

- [ ] Multi-agent orchestration
- [ ] Memory system for long-term context
- [ ] Plugin architecture for custom tools
- [ ] Web UI dashboard
- [ ] Kubernetes deployment templates
- [ ] Performance benchmarks
- [ ] Multi-language support

## License

MIT License - See [LICENSE](LICENSE) for details

## Support

- 📖 [Documentation](https://github.com/yourusername/comet-agentic-browser/wiki)
- 💬 [Discussions](https://github.com/yourusername/comet-agentic-browser/discussions)
- 🐛 [Issues](https://github.com/yourusername/comet-agentic-browser/issues)
- 📧 Contact: your-email@example.com

## Acknowledgments

- Built with [LangChain](https://python.langchain.com/)
- Browser automation via [Playwright](https://playwright.dev/)
- LLM inference through [Ollama](https://ollama.ai/)
- Inspired by autonomous agents and browser automation tools

---

**Made for the open-source community. Built with GitHub Student Pack benefits.** ❤️
