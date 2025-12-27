# Comet Agentic Browser - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     COMET AGENTIC BROWSER                       │
│                  Autonomous Web Browsing Agent                  │
└─────────────────────────────────────────────────────────────────┘

                              USER
                                │
                                │ Goal/Task
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                        AgenticBrowser                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Main Agent Loop                          │ │
│  │                                                            │ │
│  │  ┌──────────────┐    ┌──────────────┐    ┌─────────────┐ │ │
│  │  │  PERCEPTION  │───▶│   REASONING  │───▶│   ACTION    │ │ │
│  │  │              │    │              │    │             │ │ │
│  │  │ Get current  │    │ LLM decides  │    │ Execute     │ │ │
│  │  │ state/info   │    │ next action  │    │ browser     │ │ │
│  │  │              │    │ using tools  │    │ tool        │ │ │
│  │  └──────────────┘    └──────────────┘    └─────────────┘ │ │
│  │         │                    │                   │        │ │
│  │         └────────────────────┴───────────────────┘        │ │
│  │                              │                            │ │
│  │                       Iterate until                       │ │
│  │                    goal accomplished                      │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
         │                                              │
         │                                              │
         ▼                                              ▼
┌──────────────────────┐                   ┌──────────────────────┐
│     LLMClient        │                   │  BrowserController   │
│                      │                   │                      │
│  ┌────────────────┐  │                   │  ┌────────────────┐  │
│  │ Ollama Support │  │                   │  │   Playwright   │  │
│  │   (Local AI)   │  │                   │  │   (Chromium)   │  │
│  └────────────────┘  │                   │  └────────────────┘  │
│  ┌────────────────┐  │                   │  ┌────────────────┐  │
│  │ OpenAI Support │  │                   │  │   Navigate     │  │
│  │  (Cloud API)   │  │                   │  │   Read Page    │  │
│  └────────────────┘  │                   │  │   Screenshot   │  │
│  ┌────────────────┐  │                   │  │   Get Info     │  │
│  │  Tool Calling  │  │                   │  └────────────────┘  │
│  │    Parsing     │  │                   │                      │
│  └────────────────┘  │                   └──────────────────────┘
└──────────────────────┘                            │
         │                                          │
         │                                          │
         ▼                                          ▼
┌──────────────────────┐                   ┌──────────────────────┐
│  LLM Model Server    │                   │   Web Pages          │
│                      │                   │                      │
│  • Mistral (local)   │                   │  • example.com       │
│  • LLaMA (local)     │                   │  • github.com        │
│  • GPT-4 (cloud)     │                   │  • Any website       │
└──────────────────────┘                   └──────────────────────┘


DATA FLOW
═════════

1. User provides goal/task
   ↓
2. AgenticBrowser initializes conversation
   ↓
3. LOOP STARTS
   │
   ├─▶ [PERCEPTION]
   │   • Get current URL
   │   • Get page title
   │   • Get page state
   │   ↓
   ├─▶ [REASONING]
   │   • Send context to LLM
   │   • LLM analyzes situation
   │   • LLM selects tool
   │   • Returns tool call JSON
   │   ↓
   ├─▶ [ACTION]
   │   • Parse tool call
   │   • Execute browser tool
   │   • Capture result
   │   • Add to conversation
   │   ↓
   └─▶ Check if complete → YES → Return result
       │                   NO  ↓
       └───────────────────────┘ Loop again


TOOL SYSTEM
═══════════

┌──────────────────────────────────────────────────────────────┐
│                        Available Tools                        │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  1. navigate(url)                                            │
│     • Navigate browser to URL                                │
│     • Wait for page load                                     │
│     • Return success/failure                                 │
│                                                               │
│  2. read_page(selector=None)                                 │
│     • Extract page text content                              │
│     • Support CSS selectors                                  │
│     • Return title + content                                 │
│                                                               │
│  3. screenshot(filename, selector=None, full_page=False)     │
│     • Take page screenshot                                   │
│     • Support element selection                              │
│     • Save to file                                           │
│                                                               │
│  4. complete(answer)                                         │
│     • Mark task as finished                                  │
│     • Provide final answer                                   │
│     • Exit agent loop                                        │
│                                                               │
└──────────────────────────────────────────────────────────────┘


CONVERSATION HISTORY
════════════════════

┌────────────────────────────────────────────────────────────┐
│  Role: system                                              │
│  Content: "You are an intelligent web browsing agent..."  │
├────────────────────────────────────────────────────────────┤
│  Role: user                                                │
│  Content: "Goal: Go to example.com and describe it"       │
├────────────────────────────────────────────────────────────┤
│  Role: assistant                                           │
│  Content: "I'll navigate to example.com"                  │
│  Tool: {"tool": "navigate", "arguments": {...}}           │
├────────────────────────────────────────────────────────────┤
│  Role: tool                                                │
│  Content: {"success": true, "result": "Navigated to..."}  │
├────────────────────────────────────────────────────────────┤
│  ...continues until task completion...                    │
└────────────────────────────────────────────────────────────┘


COMPONENT INTERACTION
═══════════════════

    AgenticBrowser
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
    LLMClient      BrowserController
         │                 │
         ▼                 ▼
    AI Model         Playwright
         │                 │
         ▼                 ▼
    Tool JSON        Web Pages
         │                 │
         └────────┬────────┘
                  │
                  ▼
              ToolResult
                  │
                  ▼
          Conversation History
                  │
                  ▼
             Final Result


FILE STRUCTURE
══════════════

comet-agentic-browser/
│
├── agent/
│   ├── __init__.py
│   └── core.py              ◀── Main agent logic
│       ├── ToolResult       (dataclass)
│       ├── LLMClient        (class)
│       └── AgenticBrowser   (class)
│
├── browser/
│   ├── __init__.py
│   └── automation.py        ◀── Browser control
│       └── BrowserController (class)
│
├── main.py                  ◀── CLI entry point
├── example.py               ◀── Usage examples
├── test.py                  ◀── Test suite
│
├── requirements.txt         ◀── Dependencies
├── README_NEW.md            ◀── User guide
├── TECHNICAL_DOCS.md        ◀── Dev docs
├── QUICKREF.md              ◀── Quick reference
└── GETTING_STARTED.md       ◀── Setup guide


KEY DESIGN PATTERNS
═══════════════════

1. Context Manager Pattern
   • Automatic resource cleanup
   • Browser lifecycle management
   • Exception-safe operations

2. Async/Await
   • Non-blocking operations
   • Concurrent I/O handling
   • Efficient resource usage

3. Agent Architecture
   • Perception-Reasoning-Action loop
   • Tool-based interactions
   • Conversation memory

4. Strategy Pattern
   • Pluggable LLM backends
   • Multiple API support
   • Configurable behavior


EXTENSION POINTS
════════════════

1. Add New Tools
   • Define in TOOLS array
   • Implement _tool_* method
   • Add routing in _act()

2. Add LLM Backend
   • Extend LLMClient
   • Implement _*_completion() method
   • Add to API type selection

3. Add Browser Features
   • Extend BrowserController
   • Add new methods
   • Expose via tools

4. Customize Agent Behavior
   • Modify system prompt
   • Adjust max_iterations
   • Change tool selection logic
```
