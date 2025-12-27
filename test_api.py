#!/usr/bin/env python3
"""
Test client for Comet Agentic Browser API
Demonstrates all API endpoints
"""

import requests
import time
import json
from typing import Optional

class BrowserAPIClient:
    """Client for interacting with Comet Browser API"""
    
    def __init__(self, base_url: str = "http://localhost:8000", api_key: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            "Content-Type": "application/json"
        }
        if api_key:
            self.headers["X-API-Key"] = api_key
    
    def health_check(self):
        """Check API health"""
        response = requests.get(f"{self.base_url}/health")
        return response.json()
    
    def browse_async(self, goal: str, model: str = "mistral", **kwargs):
        """Submit browsing task asynchronously"""
        payload = {
            "goal": goal,
            "model": model,
            **kwargs
        }
        response = requests.post(
            f"{self.base_url}/browse",
            headers=self.headers,
            json=payload
        )
        return response.json()
    
    def browse_sync(self, goal: str, model: str = "mistral", **kwargs):
        """Submit browsing task synchronously (blocking)"""
        payload = {
            "goal": goal,
            "model": model,
            **kwargs
        }
        response = requests.post(
            f"{self.base_url}/browse/sync",
            headers=self.headers,
            json=payload
        )
        return response.json()
    
    def get_task_status(self, task_id: str):
        """Get status of a task"""
        response = requests.get(f"{self.base_url}/tasks/{task_id}")
        return response.json()
    
    def list_tasks(self, limit: int = 10, status: Optional[str] = None):
        """List all tasks"""
        params = {"limit": limit}
        if status:
            params["status"] = status
        
        response = requests.get(f"{self.base_url}/tasks", params=params)
        return response.json()
    
    def delete_task(self, task_id: str):
        """Delete a task"""
        response = requests.delete(f"{self.base_url}/tasks/{task_id}")
        return response.json()
    
    def list_models(self):
        """List available LLM models"""
        response = requests.get(f"{self.base_url}/models")
        return response.json()
    
    def wait_for_task(self, task_id: str, poll_interval: float = 2.0, timeout: float = 120.0):
        """Wait for a task to complete"""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            status = self.get_task_status(task_id)
            
            if status['status'] in ['completed', 'failed']:
                return status
            
            print(f"Status: {status['status']}... waiting...")
            time.sleep(poll_interval)
        
        raise TimeoutError(f"Task {task_id} did not complete within {timeout} seconds")


def main():
    """Demo script"""
    print("🤖 Comet Agentic Browser - API Test Client")
    print("=" * 60)
    
    # Initialize client
    client = BrowserAPIClient()
    
    # 1. Health check
    print("\n1️⃣  Health Check")
    print("-" * 60)
    health = client.health_check()
    print(json.dumps(health, indent=2))
    
    if not health.get('ollama_available'):
        print("\n⚠️  Warning: Ollama not available. Some tests may fail.")
        print("   Start Ollama with: ollama serve")
        return
    
    # 2. List models
    print("\n2️⃣  Available Models")
    print("-" * 60)
    models = client.list_models()
    if models.get('available'):
        for model in models['models'][:3]:  # Show first 3
            print(f"  - {model['name']}")
    
    # 3. Synchronous browse (simple, blocking)
    print("\n3️⃣  Synchronous Browse (Blocking)")
    print("-" * 60)
    print("Task: Go to example.com")
    
    try:
        result = client.browse_sync(
            goal="Go to example.com and tell me the page title",
            model="mistral",
            max_iterations=5
        )
        
        if result.get('success'):
            print(f"✅ Success!")
            print(f"Result: {result['result']['result'][:200]}...")
        else:
            print(f"❌ Failed: {result}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 4. Asynchronous browse (non-blocking)
    print("\n4️⃣  Asynchronous Browse (Non-blocking)")
    print("-" * 60)
    print("Task: Go to httpbin.org")
    
    try:
        # Submit task
        task = client.browse_async(
            goal="Navigate to httpbin.org and describe what you see",
            model="mistral",
            max_iterations=5
        )
        
        task_id = task['task_id']
        print(f"Task ID: {task_id}")
        print(f"Status: {task['status']}")
        
        # Wait for completion
        print("Waiting for task to complete...")
        final_status = client.wait_for_task(task_id, timeout=60)
        
        if final_status['status'] == 'completed':
            print(f"✅ Completed!")
            print(f"Result: {final_status['result']['result'][:200]}...")
        else:
            print(f"❌ Failed: {final_status.get('error')}")
    
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # 5. List all tasks
    print("\n5️⃣  List Recent Tasks")
    print("-" * 60)
    tasks = client.list_tasks(limit=5)
    for task in tasks:
        status_emoji = {
            'completed': '✅',
            'failed': '❌',
            'running': '🔄',
            'pending': '⏳'
        }.get(task['status'], '❓')
        
        print(f"{status_emoji} {task['task_id'][:8]}... - {task['status']} - {task['goal'][:40]}...")
    
    print("\n" + "=" * 60)
    print("✅ API test complete!")
    print("\nInteractive docs available at: http://localhost:8000/docs")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupted by user")
    except requests.exceptions.ConnectionError:
        print("\n❌ Error: Could not connect to API")
        print("   Make sure the API is running: python -m uvicorn api.app:app")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
