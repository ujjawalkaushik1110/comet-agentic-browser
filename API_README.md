# Comet Agentic Browser - API Documentation

## 🌐 REST API for Autonomous Web Browsing

This API provides endpoints to control the Comet Agentic Browser programmatically.

## 🚀 Quick Start

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Start Ollama (in separate terminal)
ollama serve
ollama pull mistral

# Start API server
python -m uvicorn api.app:app --reload --host 0.0.0.0 --port 8000
```

Access at:
- **API**: http://localhost:8000
- **Interactive Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Docker

```bash
docker-compose up -d
```

## 📖 API Endpoints

### 1. Health Check

**GET** `/health`

Check API and Ollama status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-12-26T10:00:00.000Z",
  "version": "1.0.0",
  "ollama_available": true
}
```

### 2. Browse (Async)

**POST** `/browse`

Submit a browsing task asynchronously.

**Request:**
```json
{
  "goal": "Go to example.com and describe what you see",
  "model": "mistral",
  "headless": true,
  "max_iterations": 15,
  "api_type": "ollama",
  "api_key": null
}
```

**Response:**
```json
{
  "task_id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "pending",
  "message": "Task scheduled successfully"
}
```

### 3. Browse Sync

**POST** `/browse/sync`

Execute browsing task synchronously (blocks until complete).

**Request:**
```json
{
  "goal": "Go to httpbin.org and read the page",
  "model": "mistral",
  "headless": true
}
```

**Response:**
```json
{
  "success": true,
  "result": {
    "success": true,
    "result": "The page shows...",
    "iterations": 3,
    "conversation_history": [...]
  }
}
```

### 4. Get Task Status

**GET** `/tasks/{task_id}`

Get status and results of a task.

**Response:**
```json
{
  "task_id": "123e4567-e89b-12d3-a456-426614174000",
  "status": "completed",
  "goal": "Go to example.com...",
  "created_at": "2025-12-26T10:00:00.000Z",
  "completed_at": "2025-12-26T10:00:15.000Z",
  "result": {
    "success": true,
    "result": "The page contains...",
    "iterations": 3
  },
  "error": null
}
```

**Status values:**
- `pending`: Task queued
- `running`: Task executing
- `completed`: Task finished successfully
- `failed`: Task failed with error

### 5. List Tasks

**GET** `/tasks?limit=10&status=completed`

List all tasks with optional filtering.

**Query Parameters:**
- `limit`: Max number of tasks (default: 10)
- `status`: Filter by status (optional)

**Response:**
```json
[
  {
    "task_id": "...",
    "status": "completed",
    "goal": "...",
    "created_at": "...",
    "completed_at": "...",
    "result": {...}
  }
]
```

### 6. Delete Task

**DELETE** `/tasks/{task_id}`

Remove a task from the list.

**Response:**
```json
{
  "message": "Task deleted successfully"
}
```

### 7. List Models

**GET** `/models`

List available LLM models (Ollama).

**Response:**
```json
{
  "available": true,
  "models": [
    {
      "name": "mistral:latest",
      "size": 4109865159,
      "modified_at": "2025-12-26T10:00:00.000Z"
    }
  ]
}
```

## 🔧 Usage Examples

### cURL

```bash
# Async task
curl -X POST http://localhost:8000/browse \
  -H "Content-Type: application/json" \
  -d '{
    "goal": "Go to example.com and tell me what you see",
    "model": "mistral"
  }'

# Get task status
curl http://localhost:8000/tasks/TASK_ID

# Sync task
curl -X POST http://localhost:8000/browse/sync \
  -H "Content-Type: application/json" \
  -d '{
    "goal": "Navigate to httpbin.org",
    "model": "mistral"
  }'
```

### Python

```python
import requests
import time

BASE_URL = "http://localhost:8000"

# Submit async task
response = requests.post(f"{BASE_URL}/browse", json={
    "goal": "Go to github.com and describe the page",
    "model": "mistral",
    "headless": True
})

task_id = response.json()["task_id"]
print(f"Task ID: {task_id}")

# Poll for completion
while True:
    status = requests.get(f"{BASE_URL}/tasks/{task_id}").json()
    print(f"Status: {status['status']}")
    
    if status['status'] in ['completed', 'failed']:
        print(f"Result: {status.get('result', {}).get('result')}")
        break
    
    time.sleep(2)
```

### JavaScript

```javascript
// Submit task
const response = await fetch('http://localhost:8000/browse', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    goal: 'Go to example.com and describe it',
    model: 'mistral'
  })
});

const { task_id } = await response.json();

// Poll for results
const checkStatus = async () => {
  const status = await fetch(`http://localhost:8000/tasks/${task_id}`);
  const data = await status.json();
  
  if (data.status === 'completed') {
    console.log('Result:', data.result.result);
  } else if (data.status === 'failed') {
    console.error('Error:', data.error);
  } else {
    setTimeout(checkStatus, 2000);
  }
};

checkStatus();
```

## 🔐 Authentication (Optional)

To enable API key authentication, set the `API_KEY` environment variable:

```bash
export API_KEY=your-secret-key
```

Then include the key in requests:

```bash
curl -X POST http://localhost:8000/browse \
  -H "X-API-Key: your-secret-key" \
  -H "Content-Type: application/json" \
  -d '{"goal": "..."}'
```

## 🌍 CORS Configuration

For production, update CORS origins in `api/app.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 📊 Rate Limiting

When deployed with Nginx, rate limiting is configured:
- 10 requests/second per IP
- Burst up to 20 requests

## 🎯 Use Cases

### 1. Web Scraping Service
```python
# Extract data from multiple pages
tasks = []
for url in urls:
    response = requests.post(f"{BASE_URL}/browse", json={
        "goal": f"Go to {url} and extract the main heading",
        "model": "mistral"
    })
    tasks.append(response.json()["task_id"])
```

### 2. Monitoring Service
```python
# Check website status
response = requests.post(f"{BASE_URL}/browse/sync", json={
    "goal": "Go to mywebsite.com and confirm it's loading",
    "model": "mistral",
    "max_iterations": 5
})
```

### 3. Content Analysis
```python
# Analyze webpage content
response = requests.post(f"{BASE_URL}/browse/sync", json={
    "goal": "Go to news.ycombinator.com and summarize the top 3 stories",
    "model": "mistral"
})
```

## 🔄 Task Lifecycle

```
1. Submit Task
   POST /browse
   ↓
2. Task Queued
   Status: pending
   ↓
3. Task Running
   Status: running
   ↓
4. Task Complete
   Status: completed/failed
   ↓
5. Retrieve Result
   GET /tasks/{id}
```

## ⚡ Performance

- **Async tasks**: Non-blocking, returns immediately
- **Sync tasks**: Blocks until complete (use for simple tasks)
- **Concurrent tasks**: Handled by FastAPI background tasks
- **Task storage**: In-memory (use Redis/DB for production)

## 🚨 Error Handling

All errors return appropriate HTTP status codes:

- `400`: Bad request (invalid parameters)
- `404`: Task not found
- `500`: Internal server error

Example error response:
```json
{
  "detail": "Task not found"
}
```

## 📝 Environment Variables

```bash
# Server
PORT=8000
HOST=0.0.0.0

# LLM
LLM_BASE_URL=http://localhost:11434
LLM_MODEL=mistral
LLM_API_TYPE=ollama

# OpenAI (alternative)
OPENAI_API_KEY=sk-...
```

## 🐳 Docker Deployment

```bash
# Build
docker build -t comet-browser-api .

# Run
docker run -p 8000:8000 \
  -e LLM_BASE_URL=http://host.docker.internal:11434 \
  comet-browser-api
```

## 📚 OpenAPI Schema

Access the full OpenAPI schema at:
- JSON: http://localhost:8000/openapi.json
- Interactive: http://localhost:8000/docs

## 🆘 Troubleshooting

### Ollama not available
```json
{
  "status": "healthy",
  "ollama_available": false
}
```
**Solution**: Start Ollama with `ollama serve`

### Task stuck in running
- Check browser is starting correctly
- Check LLM is responding
- Review logs for errors

### Out of memory
- Reduce `max_iterations`
- Use headless mode
- Increase container memory limit

## 📞 Support

- Documentation: `/docs`
- Health check: `/health`
- Repository: https://github.com/ujjawalkaushik1110/comet-agentic-browser
