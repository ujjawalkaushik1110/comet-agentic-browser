"""
Browser automation using Playwright.
Provides headless Chromium control for the Agentic Browser.
"""

import logging
from pathlib import Path
from typing import Dict, Any, Optional
from playwright.async_api import async_playwright, Browser, Page, BrowserContext


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BrowserController:
    """
    Browser automation controller using Playwright.
    Manages headless Chromium browser instance.
    """
    
    def __init__(
        self,
        headless: bool = True,
        viewport_width: int = 1280,
        viewport_height: int = 720,
        timeout: int = 30000,
        screenshot_dir: str = "screenshots"
    ):
        """
        Initialize the Browser Controller.
        
        Args:
            headless: Run browser in headless mode
            viewport_width: Browser viewport width
            viewport_height: Browser viewport height
            timeout: Default timeout for operations in milliseconds
            screenshot_dir: Directory to save screenshots
        """
        self.headless = headless
        self.viewport_width = viewport_width
        self.viewport_height = viewport_height
        self.timeout = timeout
        self.screenshot_dir = Path(screenshot_dir)
        
        self.playwright = None
        self.browser: Optional[Browser] = None
        self.context: Optional[BrowserContext] = None
        self.page: Optional[Page] = None
        
        # Ensure screenshot directory exists
        self.screenshot_dir.mkdir(exist_ok=True)
        
    async def __aenter__(self):
        """Async context manager entry."""
        await self.start()
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.close()
        
    async def start(self):
        """Start the browser instance."""
        logger.info("Starting Playwright browser...")
        
        self.playwright = await async_playwright().start()
        
        self.browser = await self.playwright.chromium.launch(
            headless=self.headless,
            args=['--no-sandbox', '--disable-setuid-sandbox']
        )
        
        self.context = await self.browser.new_context(
            viewport={'width': self.viewport_width, 'height': self.viewport_height},
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )
        
        self.page = await self.context.new_page()
        self.page.set_default_timeout(self.timeout)
        
        logger.info("Browser started successfully")
        
    async def close(self):
        """Close the browser instance."""
        logger.info("Closing browser...")
        
        if self.page:
            await self.page.close()
            
        if self.context:
            await self.context.close()
            
        if self.browser:
            await self.browser.close()
            
        if self.playwright:
            await self.playwright.stop()
            
        logger.info("Browser closed")
        
    async def navigate(self, url: str) -> Dict[str, Any]:
        """
        Navigate to a URL.
        
        Args:
            url: The URL to navigate to
            
        Returns:
            Dict containing navigation response info
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        logger.info(f"Navigating to: {url}")
        
        try:
            response = await self.page.goto(url, wait_until='domcontentloaded')
            
            # Wait a bit for dynamic content
            await self.page.wait_for_load_state('networkidle', timeout=5000)
            
            return {
                'url': self.page.url,
                'status': response.status if response else None,
                'success': True
            }
        except Exception as e:
            logger.error(f"Navigation error: {e}")
            return {
                'url': url,
                'status': None,
                'success': False,
                'error': str(e)
            }
    
    async def get_content(self, selector: Optional[str] = None) -> Dict[str, Any]:
        """
        Read page content.
        
        Args:
            selector: Optional CSS selector to read specific elements.
                     If None, reads the entire page.
                     
        Returns:
            Dict containing page title and text content
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        logger.info(f"Reading page content (selector: {selector or 'full page'})")
        
        try:
            title = await self.page.title()
            
            if selector:
                # Read specific element(s)
                elements = await self.page.query_selector_all(selector)
                texts = []
                for element in elements:
                    text = await element.inner_text()
                    texts.append(text)
                content = '\n\n'.join(texts)
            else:
                # Read entire page body
                content = await self.page.evaluate('''() => {
                    // Remove script and style tags
                    const clone = document.body.cloneNode(true);
                    const scripts = clone.querySelectorAll('script, style, noscript');
                    scripts.forEach(el => el.remove());
                    return clone.innerText;
                }''')
            
            return {
                'title': title,
                'content': content.strip(),
                'url': self.page.url,
                'length': len(content)
            }
            
        except Exception as e:
            logger.error(f"Error reading page content: {e}")
            raise
    
    async def screenshot(
        self,
        filename: str,
        selector: Optional[str] = None,
        full_page: bool = False
    ) -> str:
        """
        Take a screenshot of the page or element.
        
        Args:
            filename: Name of the screenshot file
            selector: Optional CSS selector to screenshot a specific element
            full_page: Whether to capture the full scrollable page
            
        Returns:
            Path to the saved screenshot
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        # Ensure filename has .png extension
        if not filename.endswith('.png'):
            filename += '.png'
            
        filepath = self.screenshot_dir / filename
        
        logger.info(f"Taking screenshot: {filepath}")
        
        try:
            if selector:
                # Screenshot specific element
                element = await self.page.query_selector(selector)
                if element:
                    await element.screenshot(path=str(filepath))
                else:
                    raise ValueError(f"Element not found: {selector}")
            else:
                # Screenshot full page or viewport
                await self.page.screenshot(
                    path=str(filepath),
                    full_page=full_page
                )
            
            logger.info(f"Screenshot saved: {filepath}")
            return str(filepath)
            
        except Exception as e:
            logger.error(f"Screenshot error: {e}")
            raise
    
    async def get_page_info(self) -> Dict[str, Any]:
        """
        Get basic information about the current page.
        
        Returns:
            Dict with page title, URL, and ready state
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        try:
            title = await self.page.title()
            url = self.page.url
            
            # Check if page is ready
            ready_state = await self.page.evaluate('document.readyState')
            
            return {
                'title': title,
                'url': url,
                'ready': ready_state == 'complete',
                'ready_state': ready_state
            }
            
        except Exception as e:
            logger.error(f"Error getting page info: {e}")
            return {
                'title': '',
                'url': '',
                'ready': False,
                'error': str(e)
            }
    
    async def click(self, selector: str) -> bool:
        """
        Click an element on the page.
        
        Args:
            selector: CSS selector for the element to click
            
        Returns:
            True if successful, False otherwise
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        try:
            await self.page.click(selector)
            logger.info(f"Clicked element: {selector}")
            return True
        except Exception as e:
            logger.error(f"Click error: {e}")
            return False
    
    async def fill(self, selector: str, text: str) -> bool:
        """
        Fill a form input with text.
        
        Args:
            selector: CSS selector for the input element
            text: Text to fill
            
        Returns:
            True if successful, False otherwise
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        try:
            await self.page.fill(selector, text)
            logger.info(f"Filled element {selector} with text")
            return True
        except Exception as e:
            logger.error(f"Fill error: {e}")
            return False
    
    async def evaluate(self, script: str) -> Any:
        """
        Execute JavaScript in the page context.
        
        Args:
            script: JavaScript code to execute
            
        Returns:
            Result of the script execution
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        try:
            result = await self.page.evaluate(script)
            return result
        except Exception as e:
            logger.error(f"Evaluate error: {e}")
            raise
    
    async def wait_for_selector(self, selector: str, timeout: Optional[int] = None) -> bool:
        """
        Wait for an element to appear on the page.
        
        Args:
            selector: CSS selector to wait for
            timeout: Timeout in milliseconds (uses default if None)
            
        Returns:
            True if element appeared, False otherwise
        """
        if not self.page:
            raise RuntimeError("Browser not started. Call start() first.")
            
        try:
            await self.page.wait_for_selector(
                selector,
                timeout=timeout or self.timeout
            )
            return True
        except Exception as e:
            logger.error(f"Wait for selector error: {e}")
            return False
