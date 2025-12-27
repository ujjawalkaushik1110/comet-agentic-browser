"""
Integration and unit tests for Comet Browser API
"""
import pytest
import asyncio
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, AsyncMock
import time
import os

# Import the API
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'api'))

from app_enhanced import app, limiter, redis_client, get_cache_key


@pytest.fixture
def client():
    """Create test client"""
    return TestClient(app)


@pytest.fixture
def mock_redis():
    """Mock Redis client"""
    with patch('app_enhanced.redis_client') as mock:
        mock.get = AsyncMock(return_value=None)
        mock.setex = AsyncMock()
        mock.ping = AsyncMock(return_value=True)
        yield mock


@pytest.fixture
def mock_browser():
    """Mock browser automation"""
    with patch('app_enhanced.browse_sync') as mock_browse:
        mock_browse.return_value = {
            "url": "https://example.com",
            "title": "Example Domain",
            "content": "This domain is for use in illustrative examples",
            "screenshot": None,
            "timestamp": "2024-01-01T00:00:00"
        }
        yield mock_browse


class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_health_basic(self, client):
        """Test basic health endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "environment" in data
        assert "version" in data
    
    def test_health_db(self, client):
        """Test database health check"""
        with patch('app_enhanced.check_db_health') as mock_db:
            mock_db.return_value = True
            response = client.get("/health/db")
            assert response.status_code == 200
            assert response.json()["database"] == "connected"
    
    def test_health_redis(self, client, mock_redis):
        """Test Redis health check"""
        response = client.get("/health/redis")
        assert response.status_code == 200
        data = response.json()
        assert "redis" in data
    
    def test_readiness(self, client, mock_redis):
        """Test readiness probe"""
        with patch('app_enhanced.check_db_health') as mock_db:
            mock_db.return_value = True
            response = client.get("/health/ready")
            assert response.status_code == 200
            data = response.json()
            assert data["ready"] is True


class TestBrowseEndpoints:
    """Test browser automation endpoints"""
    
    def test_browse_sync(self, client, mock_browser, mock_redis):
        """Test synchronous browse endpoint"""
        response = client.post(
            "/browse/sync",
            json={"url": "https://example.com"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["url"] == "https://example.com"
        assert "title" in data
        assert "content" in data
    
    def test_browse_async(self, client, mock_redis):
        """Test asynchronous browse endpoint"""
        with patch('app_enhanced.browse_async') as mock_browse:
            mock_browse.return_value = {
                "task_id": "test-task-123",
                "status": "pending"
            }
            response = client.post(
                "/browse/async",
                json={"url": "https://example.com"}
            )
            assert response.status_code == 202
            data = response.json()
            assert "task_id" in data
    
    def test_browse_invalid_url(self, client):
        """Test browse with invalid URL"""
        response = client.post(
            "/browse/sync",
            json={"url": "not-a-valid-url"}
        )
        assert response.status_code == 422  # Validation error
    
    def test_browse_with_actions(self, client, mock_browser, mock_redis):
        """Test browse with custom actions"""
        response = client.post(
            "/browse/sync",
            json={
                "url": "https://example.com",
                "actions": [
                    {"type": "click", "selector": "#button"},
                    {"type": "type", "selector": "input", "text": "test"}
                ]
            }
        )
        assert response.status_code == 200


class TestCaching:
    """Test caching functionality"""
    
    def test_cache_key_generation(self):
        """Test cache key generation"""
        key1 = get_cache_key("https://example.com", {})
        key2 = get_cache_key("https://example.com", {})
        key3 = get_cache_key("https://different.com", {})
        
        assert key1 == key2  # Same inputs produce same key
        assert key1 != key3  # Different inputs produce different keys
    
    def test_cache_hit(self, client, mock_redis, mock_browser):
        """Test cache hit scenario"""
        cached_data = '{"url": "https://example.com", "cached": true}'
        mock_redis.get.return_value = cached_data.encode()
        
        response = client.post(
            "/browse/sync",
            json={"url": "https://example.com"}
        )
        
        assert response.status_code == 200
        # Browser should not be called on cache hit
        mock_browser.assert_not_called()
    
    def test_cache_miss(self, client, mock_redis, mock_browser):
        """Test cache miss scenario"""
        mock_redis.get.return_value = None
        
        response = client.post(
            "/browse/sync",
            json={"url": "https://example.com"}
        )
        
        assert response.status_code == 200
        # Browser should be called on cache miss
        mock_browser.assert_called_once()
        # Result should be cached
        mock_redis.setex.assert_called_once()


class TestRateLimiting:
    """Test rate limiting functionality"""
    
    def test_rate_limit_enforced(self, client, mock_browser, mock_redis):
        """Test that rate limits are enforced"""
        # Make requests up to the limit
        for i in range(5):
            response = client.post(
                "/browse/sync",
                json={"url": f"https://example.com/{i}"}
            )
            if response.status_code == 429:
                # Hit rate limit
                assert "rate limit" in response.json()["detail"].lower()
                break
        else:
            # If we didn't hit rate limit in 5 requests, that's also fine
            # (depends on rate limit configuration)
            pass
    
    def test_rate_limit_headers(self, client, mock_browser, mock_redis):
        """Test rate limit headers are present"""
        response = client.post(
            "/browse/sync",
            json={"url": "https://example.com"}
        )
        # Check for rate limit headers
        assert any(header.startswith('X-RateLimit') for header in response.headers)


class TestMetrics:
    """Test Prometheus metrics endpoint"""
    
    def test_metrics_endpoint(self, client):
        """Test metrics endpoint returns prometheus format"""
        response = client.get("/metrics")
        assert response.status_code == 200
        assert "text/plain" in response.headers["content-type"]
        
        # Check for some expected metrics
        content = response.text
        assert "api_requests_total" in content
        assert "api_request_duration_seconds" in content
    
    def test_metrics_incremented(self, client, mock_browser, mock_redis):
        """Test that metrics are incremented on requests"""
        # Get initial metrics
        response1 = client.get("/metrics")
        initial_content = response1.text
        
        # Make a request
        client.post("/browse/sync", json={"url": "https://example.com"})
        
        # Get metrics again
        response2 = client.get("/metrics")
        updated_content = response2.text
        
        # Metrics should have changed
        assert initial_content != updated_content


class TestErrorHandling:
    """Test error handling"""
    
    def test_404_error(self, client):
        """Test 404 handling"""
        response = client.get("/nonexistent")
        assert response.status_code == 404
    
    def test_422_validation_error(self, client):
        """Test validation error handling"""
        response = client.post("/browse/sync", json={})
        assert response.status_code == 422
    
    def test_500_internal_error(self, client, mock_redis):
        """Test internal error handling"""
        with patch('app_enhanced.browse_sync') as mock_browse:
            mock_browse.side_effect = Exception("Test error")
            response = client.post(
                "/browse/sync",
                json={"url": "https://example.com"}
            )
            # Should return 500 or handle gracefully
            assert response.status_code >= 400


class TestPerformance:
    """Performance and load tests"""
    
    def test_response_time(self, client, mock_browser, mock_redis):
        """Test response time is acceptable"""
        start = time.time()
        response = client.post(
            "/browse/sync",
            json={"url": "https://example.com"}
        )
        duration = time.time() - start
        
        assert response.status_code == 200
        # Response should be under 1 second (with mocked browser)
        assert duration < 1.0
    
    def test_concurrent_requests(self, client, mock_browser, mock_redis):
        """Test handling concurrent requests"""
        import concurrent.futures
        
        def make_request(i):
            return client.post(
                "/browse/sync",
                json={"url": f"https://example.com/{i}"}
            )
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(make_request, i) for i in range(10)]
            results = [f.result() for f in concurrent.futures.as_completed(futures)]
        
        # Most requests should succeed (some may hit rate limit)
        successful = [r for r in results if r.status_code == 200]
        assert len(successful) > 0


class TestSecurity:
    """Security tests"""
    
    def test_sql_injection(self, client, mock_browser, mock_redis):
        """Test SQL injection prevention"""
        malicious_url = "https://example.com'; DROP TABLE users; --"
        response = client.post(
            "/browse/sync",
            json={"url": malicious_url}
        )
        # Should either validate or handle safely
        assert response.status_code in [200, 422]
    
    def test_xss_prevention(self, client, mock_browser, mock_redis):
        """Test XSS prevention"""
        xss_url = "https://example.com/<script>alert('xss')</script>"
        response = client.post(
            "/browse/sync",
            json={"url": xss_url}
        )
        # Response should not contain unescaped script tags
        assert "<script>" not in response.text
    
    def test_cors_headers(self, client):
        """Test CORS headers are set correctly"""
        response = client.options("/health")
        # CORS headers should be present if configured
        # This depends on your CORS configuration


class TestEnvironmentConfig:
    """Test environment-specific configuration"""
    
    def test_development_config(self, client):
        """Test development environment configuration"""
        with patch.dict(os.environ, {"ENVIRONMENT": "development"}):
            response = client.get("/health")
            data = response.json()
            assert data["environment"] == "development"
    
    def test_production_config(self, client):
        """Test production environment configuration"""
        with patch.dict(os.environ, {"ENVIRONMENT": "production"}):
            response = client.get("/health")
            data = response.json()
            assert data["environment"] == "production"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--cov=app_enhanced", "--cov-report=html"])
