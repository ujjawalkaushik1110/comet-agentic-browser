"""
FastAPI application for Comet Agentic Browser
Provides REST API endpoints for autonomous web browsing
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
import asyncio
import logging
import os
from datetime import datetime
import uuid

# Import the agentic browser
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from agent.core import AgenticBrowser

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Comet Agentic Browser API",
    description="AI-powered autonomous web browsing API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory task storage (use Redis/database in production)
tasks: Dict[str, Dict[str, Any]] = {}

# Request/Response models
class BrowseRequest(BaseModel):
    """Request model for browse endpoint"""
    goal: str = Field(..., description="The browsing goal/task to accomplish")
    model: str = Field(default="mistral", description="LLM model to use")
    headless: bool = Field(default=True, description="Run browser in headless mode")
    max_iterations: int = Field(default=15, description="Maximum agent iterations")
    api_type: str = Field(default="ollama", description="LLM API type (ollama, openai)")
    api_key: Optional[str] = Field(default=None, description="API key for cloud LLM services")
    
    class Config:
        json_schema_extra = {
            "example": {
                "goal": "Go to example.com and describe what you see",
                "model": "mistral",
                "headless": True,
                "max_iterations": 15
            }
        }


class BrowseResponse(BaseModel):
    """Response model for browse endpoint"""
    task_id: str
    status: str
    message: str


class TaskStatus(BaseModel):
    """Task status model"""
    task_id: str
    status: str  # pending, running, completed, failed
    goal: str
    created_at: str
    completed_at: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    timestamp: str
    version: str
    ollama_available: bool


# Background task executor
async def execute_browse_task(task_id: str, request: BrowseRequest):
    """Execute a browsing task in the background"""
    logger.info(f"Starting task {task_id}: {request.goal}")
    
    tasks[task_id]["status"] = "running"
    
    try:
        # Get configuration from environment or request
        base_url = os.getenv("LLM_BASE_URL", "http://localhost:11434")
        api_key = request.api_key or os.getenv("OPENAI_API_KEY")
        
        async with AgenticBrowser(
            model=request.model,
            headless=request.headless,
            max_iterations=request.max_iterations,
            base_url=base_url,
            api_type=request.api_type,
            api_key=api_key
        ) as agent:
            result = await agent.run(request.goal)
            
            tasks[task_id]["status"] = "completed"
            tasks[task_id]["completed_at"] = datetime.utcnow().isoformat()
            tasks[task_id]["result"] = result
            
            logger.info(f"Task {task_id} completed successfully")
            
    except Exception as e:
        logger.error(f"Task {task_id} failed: {e}", exc_info=True)
        tasks[task_id]["status"] = "failed"
        tasks[task_id]["completed_at"] = datetime.utcnow().isoformat()
        tasks[task_id]["error"] = str(e)


# API Endpoints
@app.get("/")
async def serve_perplexity():
    """Serve Perplexity-style AI search interface"""
    return FileResponse('static/perplexity.html')


@app.get("/app")
async def serve_app():
    """Serve the original web application"""
    return FileResponse('static/index.html')


# Mount static files
static_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_path):
    app.mount("/static", StaticFiles(directory=static_path), name="static")

# Mount screenshots directory for captured images
screens_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "screenshots")
if os.path.exists(screens_path):
    app.mount("/screenshots", StaticFiles(directory=screens_path), name="screenshots")


@app.get("/api", response_model=Dict[str, str])
async def api_root():
    """API information endpoint"""
    return {
        "message": "Comet Agentic Browser API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
        "app": "/app"
    }


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    import aiohttp
    
    # Check Ollama availability
    ollama_available = False
    try:
        base_url = os.getenv("LLM_BASE_URL", "http://localhost:11434")
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{base_url}/api/tags", timeout=aiohttp.ClientTimeout(total=2)) as response:
                ollama_available = response.status == 200
    except:
        pass
    
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0",
        ollama_available=ollama_available
    )


@app.post("/browse", response_model=BrowseResponse)
async def browse(request: BrowseRequest, background_tasks: BackgroundTasks):
    """
    Start a browsing task asynchronously
    
    Returns a task_id that can be used to check status and retrieve results
    """
    task_id = str(uuid.uuid4())
    
    # Create task record
    tasks[task_id] = {
        "task_id": task_id,
        "status": "pending",
        "goal": request.goal,
        "created_at": datetime.utcnow().isoformat(),
        "completed_at": None,
        "result": None,
        "error": None
    }
    
    # Schedule background task
    background_tasks.add_task(execute_browse_task, task_id, request)
    
    return BrowseResponse(
        task_id=task_id,
        status="pending",
        message=f"Task {task_id} scheduled successfully"
    )


@app.post("/browse/sync", response_model=Dict[str, Any])
async def browse_sync(request: BrowseRequest):
    """
    Execute a browsing task synchronously (blocking)
    
    Use for simple tasks or when you need immediate results
    """
    logger.info(f"Synchronous browse request: {request.goal}")
    
    try:
        base_url = os.getenv("LLM_BASE_URL", "http://localhost:11434")
        api_key = request.api_key or os.getenv("OPENAI_API_KEY")
        
        async with AgenticBrowser(
            model=request.model,
            headless=request.headless,
            max_iterations=request.max_iterations,
            base_url=base_url,
            api_type=request.api_type,
            api_key=api_key
        ) as agent:
            result = await agent.run(request.goal)
            
            return {
                "success": True,
                "result": result
            }
            
    except Exception as e:
        logger.error(f"Synchronous browse failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/tasks/{task_id}", response_model=TaskStatus)
async def get_task_status(task_id: str):
    """Get the status of a browsing task"""
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
    
    return TaskStatus(**tasks[task_id])


@app.get("/tasks", response_model=List[TaskStatus])
async def list_tasks(limit: int = 10, status: Optional[str] = None):
    """List all tasks (optionally filtered by status)"""
    filtered_tasks = tasks.values()
    
    if status:
        filtered_tasks = [t for t in filtered_tasks if t["status"] == status]
    
    # Sort by created_at descending
    sorted_tasks = sorted(
        filtered_tasks,
        key=lambda x: x["created_at"],
        reverse=True
    )
    
    return [TaskStatus(**t) for t in sorted_tasks[:limit]]


@app.delete("/tasks/{task_id}")
async def delete_task(task_id: str):
    """Delete a task from the task list"""
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
    
    del tasks[task_id]
    return {"message": f"Task {task_id} deleted successfully"}


@app.get("/models", response_model=Dict[str, Any])
async def list_models():
    """List available LLM models"""
    import aiohttp
    
    base_url = os.getenv("LLM_BASE_URL", "http://localhost:11434")
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{base_url}/api/tags") as response:
                if response.status == 200:
                    data = await response.json()
                    return {
                        "available": True,
                        "models": data.get("models", [])
                    }
    except Exception as e:
        logger.error(f"Failed to list models: {e}")
    
    return {
        "available": False,
        "models": [],
        "error": "Ollama not available"
    }


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
    uvicorn.run(
        "app:app",
        host=host,
        port=port,
        reload=True,
        log_level="info"
    )
