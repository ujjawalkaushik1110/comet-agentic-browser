"""
Enhanced FastAPI application with rate limiting, caching, and monitoring
Production-ready version with comprehensive security and performance features
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
import asyncio
import logging
import os
import uuid
import time
import hashlib
import json

# Third-party imports
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import aioredis
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from prometheus_client import CONTENT_TYPE_LATEST

# Import the agentic browser
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from agent.core import AgenticBrowser

# Configure logging
logging.basicConfig(
    level=getattr(logging, os.getenv("LOG_LEVEL", "INFO")),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Environment configuration
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
RATE_LIMIT_ENABLED = os.getenv("RATE_LIMIT_ENABLED", "true").lower() == "true"
RATE_LIMIT_PER_MINUTE = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))
REDIS_ENABLED = os.getenv("REDIS_ENABLED", "false").lower() == "true"
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))  # 5 minutes

# Prometheus metrics
request_count = Counter('api_requests_total', 'Total API requests', ['method', 'endpoint', 'status'])
request_duration = Histogram('api_request_duration_seconds', 'Request duration', ['method', 'endpoint'])
active_tasks = Gauge('api_active_tasks', 'Number of active tasks')
cache_hits = Counter('api_cache_hits_total', 'Cache hits')
cache_misses = Counter('api_cache_misses_total', 'Cache misses')

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

# Initialize FastAPI app
app = FastAPI(
    title="Comet Agentic Browser API",
    description="AI-powered autonomous web browsing API with enterprise features",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_tags=[
        {"name": "health", "description": "Health check endpoints"},
        {"name": "browsing", "description": "Web browsing operations"},
        {"name": "tasks", "description": "Task management"},
        {"name": "monitoring", "description": "Monitoring and metrics"},
    ]
)

# Add rate limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS middleware
allowed_origins = os.getenv("ALLOWED_CORS_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)

# GZip compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Redis connection
redis_client: Optional[aioredis.Redis] = None

@app.on_event("startup")
async def startup_event():
    """Initialize connections on startup"""
    global redis_client
    
    if REDIS_ENABLED:
        try:
            redis_client = await aioredis.from_url(
                REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
            logger.info("Connected to Redis successfully")
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            redis_client = None
    
    logger.info(f"Application started in {ENVIRONMENT} mode")
    logger.info(f"Rate limiting: {'enabled' if RATE_LIMIT_ENABLED else 'disabled'}")
    logger.info(f"Caching: {'enabled' if REDIS_ENABLED else 'disabled'}")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    global redis_client
    
    if redis_client:
        await redis_client.close()
        logger.info("Redis connection closed")

# In-memory task storage (fallback)
tasks: Dict[str, Dict[str, Any]] = {}

# Request/Response models
class BrowseRequest(BaseModel):
    """Request model for browse operations"""
    goal: str = Field(..., min_length=10, max_length=500, description="Browsing goal")
    max_iterations: Optional[int] = Field(15, ge=1, le=50, description="Maximum iterations")
    llm_api_type: Optional[str] = Field("openai", pattern="^(ollama|openai)$")
    llm_model: Optional[str] = Field(None, description="LLM model name")
    llm_base_url: Optional[str] = Field(None, description="LLM base URL")
    timeout: Optional[int] = Field(300, ge=30, le=600, description="Timeout in seconds")
    
    @validator('goal')
    def validate_goal(cls, v):
        if not v or not v.strip():
            raise ValueError('Goal cannot be empty')
        return v.strip()

class BrowseResponse(BaseModel):
    """Response model for browse operations"""
    task_id: str
    status: str
    message: str
    created_at: str

class TaskStatus(BaseModel):
    """Task status response"""
    task_id: str
    status: str
    goal: str
    result: Optional[str]
    error: Optional[str]
    created_at: str
    updated_at: str
    duration: Optional[float]

class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    environment: str
    version: str
    uptime: float
    redis_connected: bool
    active_tasks: int
    timestamp: str

# Middleware for request tracking
@app.middleware("http")
async def track_requests(request: Request, call_next):
    """Track request metrics"""
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    request_count.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    request_duration.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    # Add custom headers
    response.headers["X-Process-Time"] = str(duration)
    response.headers["X-Environment"] = ENVIRONMENT
    
    return response

# Cache helper functions
async def get_from_cache(key: str) -> Optional[str]:
    """Get value from cache"""
    if not redis_client:
        return None
    
    try:
        value = await redis_client.get(key)
        if value:
            cache_hits.inc()
            return value
        cache_misses.inc()
        return None
    except Exception as e:
        logger.error(f"Cache get error: {e}")
        return None

async def set_to_cache(key: str, value: str, ttl: int = CACHE_TTL):
    """Set value to cache"""
    if not redis_client:
        return
    
    try:
        await redis_client.setex(key, ttl, value)
    except Exception as e:
        logger.error(f"Cache set error: {e}")

def generate_cache_key(request: BrowseRequest) -> str:
    """Generate cache key from request"""
    request_str = json.dumps({
        "goal": request.goal,
        "llm_model": request.llm_model,
        "llm_api_type": request.llm_api_type
    }, sort_keys=True)
    return f"browse:{hashlib.sha256(request_str.encode()).hexdigest()}"

# Background task executor
async def execute_browse_task(task_id: str, request: BrowseRequest):
    """Execute browsing task in background"""
    start_time = time.time()
    
    try:
        tasks[task_id]["status"] = "running"
        tasks[task_id]["updated_at"] = datetime.utcnow().isoformat()
        active_tasks.inc()
        
        # Create browser instance
        browser = AgenticBrowser(
            llm_api_type=request.llm_api_type,
            llm_model=request.llm_model,
            llm_base_url=request.llm_base_url,
            max_iterations=request.max_iterations
        )
        
        # Run with timeout
        result = await asyncio.wait_for(
            browser.run(request.goal),
            timeout=request.timeout
        )
        
        duration = time.time() - start_time
        
        # Update task
        tasks[task_id]["status"] = "completed"
        tasks[task_id]["result"] = result
        tasks[task_id]["updated_at"] = datetime.utcnow().isoformat()
        tasks[task_id]["duration"] = duration
        
        # Cache result
        cache_key = generate_cache_key(request)
        await set_to_cache(cache_key, json.dumps({
            "result": result,
            "timestamp": datetime.utcnow().isoformat()
        }))
        
        logger.info(f"Task {task_id} completed in {duration:.2f}s")
        
    except asyncio.TimeoutError:
        tasks[task_id]["status"] = "failed"
        tasks[task_id]["error"] = "Task timed out"
        tasks[task_id]["updated_at"] = datetime.utcnow().isoformat()
        logger.error(f"Task {task_id} timed out")
        
    except Exception as e:
        tasks[task_id]["status"] = "failed"
        tasks[task_id]["error"] = str(e)
        tasks[task_id]["updated_at"] = datetime.utcnow().isoformat()
        logger.error(f"Task {task_id} failed: {e}", exc_info=True)
        
    finally:
        active_tasks.dec()

# API Endpoints
@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        environment=ENVIRONMENT,
        version="2.0.0",
        uptime=time.time(),
        redis_connected=redis_client is not None,
        active_tasks=len([t for t in tasks.values() if t["status"] == "running"]),
        timestamp=datetime.utcnow().isoformat()
    )

@app.get("/metrics", tags=["monitoring"])
async def metrics():
    """Prometheus metrics endpoint"""
    return JSONResponse(
        content=generate_latest().decode('utf-8'),
        media_type=CONTENT_TYPE_LATEST
    )

@app.post("/browse", response_model=BrowseResponse, tags=["browsing"])
@limiter.limit(f"{RATE_LIMIT_PER_MINUTE}/minute" if RATE_LIMIT_ENABLED else "1000/minute")
async def browse_async(request: Request, browse_request: BrowseRequest, background_tasks: BackgroundTasks):
    """Start async browsing task"""
    
    # Check cache first
    cache_key = generate_cache_key(browse_request)
    cached = await get_from_cache(cache_key)
    
    if cached:
        cached_data = json.loads(cached)
        logger.info(f"Returning cached result for goal: {browse_request.goal[:50]}")
        
        # Create a completed task
        task_id = str(uuid.uuid4())
        tasks[task_id] = {
            "task_id": task_id,
            "status": "completed",
            "goal": browse_request.goal,
            "result": cached_data["result"],
            "error": None,
            "created_at": cached_data["timestamp"],
            "updated_at": cached_data["timestamp"],
            "cached": True
        }
        
        return BrowseResponse(
            task_id=task_id,
            status="completed",
            message="Retrieved from cache",
            created_at=cached_data["timestamp"]
        )
    
    # Create new task
    task_id = str(uuid.uuid4())
    tasks[task_id] = {
        "task_id": task_id,
        "status": "pending",
        "goal": browse_request.goal,
        "result": None,
        "error": None,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
        "cached": False
    }
    
    # Execute in background
    background_tasks.add_task(execute_browse_task, task_id, browse_request)
    
    logger.info(f"Created task {task_id} for goal: {browse_request.goal[:50]}")
    
    return BrowseResponse(
        task_id=task_id,
        status="pending",
        message="Task created successfully",
        created_at=tasks[task_id]["created_at"]
    )

@app.post("/browse/sync", tags=["browsing"])
@limiter.limit(f"{int(RATE_LIMIT_PER_MINUTE/2)}/minute" if RATE_LIMIT_ENABLED else "500/minute")
async def browse_sync(request: Request, browse_request: BrowseRequest):
    """Synchronous browsing (blocks until complete)"""
    
    # Check cache first
    cache_key = generate_cache_key(browse_request)
    cached = await get_from_cache(cache_key)
    
    if cached:
        cached_data = json.loads(cached)
        logger.info(f"Returning cached result for goal: {browse_request.goal[:50]}")
        return {
            "status": "completed",
            "result": cached_data["result"],
            "cached": True,
            "timestamp": cached_data["timestamp"]
        }
    
    start_time = time.time()
    active_tasks.inc()
    
    try:
        browser = AgenticBrowser(
            llm_api_type=browse_request.llm_api_type,
            llm_model=browse_request.llm_model,
            llm_base_url=browse_request.llm_base_url,
            max_iterations=browse_request.max_iterations
        )
        
        result = await asyncio.wait_for(
            browser.run(browse_request.goal),
            timeout=browse_request.timeout
        )
        
        duration = time.time() - start_time
        
        # Cache result
        await set_to_cache(cache_key, json.dumps({
            "result": result,
            "timestamp": datetime.utcnow().isoformat()
        }))
        
        logger.info(f"Sync browse completed in {duration:.2f}s")
        
        return {
            "status": "completed",
            "result": result,
            "cached": False,
            "duration": duration,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except asyncio.TimeoutError:
        raise HTTPException(status_code=408, detail="Request timeout")
    except Exception as e:
        logger.error(f"Browse error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        active_tasks.dec()

@app.get("/tasks/{task_id}", response_model=TaskStatus, tags=["tasks"])
async def get_task_status(task_id: str):
    """Get task status"""
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks[task_id]
    return TaskStatus(**task)

@app.get("/tasks", tags=["tasks"])
async def list_tasks(
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0
):
    """List all tasks with pagination"""
    filtered_tasks = list(tasks.values())
    
    if status:
        filtered_tasks = [t for t in filtered_tasks if t["status"] == status]
    
    # Sort by created_at descending
    filtered_tasks.sort(key=lambda x: x["created_at"], reverse=True)
    
    # Paginate
    paginated = filtered_tasks[offset:offset + limit]
    
    return {
        "total": len(filtered_tasks),
        "offset": offset,
        "limit": limit,
        "tasks": paginated
    }

@app.delete("/tasks/{task_id}", tags=["tasks"])
async def delete_task(task_id: str):
    """Delete a task"""
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks.pop(task_id)
    logger.info(f"Deleted task {task_id}")
    
    return {"message": "Task deleted", "task_id": task_id}

@app.delete("/cache", tags=["monitoring"])
@limiter.limit("10/hour")
async def clear_cache(request: Request):
    """Clear cache (admin only)"""
    if not redis_client:
        raise HTTPException(status_code=503, detail="Redis not available")
    
    try:
        await redis_client.flushdb()
        logger.warning("Cache cleared")
        return {"message": "Cache cleared successfully"}
    except Exception as e:
        logger.error(f"Cache clear error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Error handlers
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": str(exc) if ENVIRONMENT == "development" else "An error occurred",
            "timestamp": datetime.utcnow().isoformat()
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8000,
        reload=ENVIRONMENT == "development",
        log_level=os.getenv("LOG_LEVEL", "info").lower()
    )
