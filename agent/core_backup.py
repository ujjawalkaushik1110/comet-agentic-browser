"""
Comet Agentic Browser Core
Implements the main AgenticBrowser class with perception-reasoning-action loop.
"""

import json
import logging
import asyncio
import re
from typing import Any, Dict, List, Optional, Union
from dataclasses import dataclass
from pathlib import Path


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class ToolResult:
    """Result from executing a tool."""
    tool_name: str
    success: bool
    result: Any
    error: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "tool_name": self.tool_name,
            "success": self.success,
            "result": str(self.result)[:1000] if self.result else None,
            "error": self.error
        }


class LLMClient:
    """
    LLM Client for interacting with local or remote language models.
    Supports Ollama, OpenAI-compatible APIs, and Anthropic.
    """
    
    def __init__(
        self,
        model: str = "mistral",
        base_url: str = "http://localhost:11434",
        api_type: str = "ollama",
        api_key: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 2000
    ):
        """
        Initialize LLM client.
        
        Args:
            model: Model name (e.g., "mistral", "llama2", "gpt-4")
            base_url: Base URL for the API
            api_type: Type of API ("ollama", "openai", "anthropic")
            api_key: API key for remote services
            temperature: Sampling temperature
            max_tokens: Maximum tokens in response
        """
        self.model = model
        self.base_url = base_url.rstrip('/')
        self.api_type = api_type.lower()
        self.api_key = api_key
        self.temperature = temperature
        self.max_tokens = max_tokens
        
    async def chat_completion(
        self,
        messages: List[Dict[str, Any]],
        tools: Optional[List[Dict[str, Any]]] = None,
        tool_choice: str = "auto"
    ) -> Dict[str, Any]:
        """
        Get chat completion with optional tool calling.
        
        Args:
            messages: List of message dicts with role and content
            tools: Optional list of tool definitions
            tool_choice: "auto", "none", or specific tool name
            
        Returns:
            Dict with response content and optional tool_calls
        """
        if self.api_type == "ollama":
            return await self._ollama_completion(messages, tools, tool_choice)
        elif self.api_type == "openai":
            return await self._openai_completion(messages, tools, tool_choice)
        else:
            raise ValueError(f"Unsupported API type: {self.api_type}")
    
    async def _ollama_completion(
        self,
        messages: List[Dict[str, Any]],
        tools: Optional[List[Dict[str, Any]]],
        tool_choice: str
    ) -> Dict[str, Any]:
        """Ollama-specific completion implementation."""
        import aiohttp
        
        # Clean messages for Ollama (remove tool messages, simplify structure)
        cleaned_messages = []
        for msg in messages:
            if msg.get("role") == "tool":
                # Convert tool results to assistant messages
                cleaned_messages.append({
                    "role": "user",
                    "content": f"Tool result: {msg.get('content', '')}"
                })
            elif msg.get("role") in ["system", "user", "assistant"]:
                cleaned_messages.append({
                    "role": msg["role"],
                    "content": msg.get("content", "")
                })
        
        # Add tool instructions to system message if tools are provided
        if tools:
            tool_prompt = self._create_tool_prompt(tools)
            # Prepend to first system message or add new system message
            if cleaned_messages and cleaned_messages[0]["role"] == "system":
                cleaned_messages[0]["content"] += f"\n\n{tool_prompt}"
            else:
                cleaned_messages.insert(0, {
                    "role": "system",
                    "content": tool_prompt
                })
        
        payload = {
            "model": self.model,
            "messages": cleaned_messages,
            "stream": False,
            "options": {
                "temperature": self.temperature,
                "num_predict": self.max_tokens
            }
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/api/chat",
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=60)
                ) as response:
                    if response.status != 200:
                        error_text = await response.text()
                        raise RuntimeError(f"Ollama API error: {error_text}")
                    
                    result = await response.json()
                    content = result.get("message", {}).get("content", "")
                    
                    # Parse tool calls from response if tools were provided
                    tool_calls = None
                    if tools:
                        tool_calls = self._parse_tool_calls_from_text(content, tools)
                    
                    return {
                        "content": content,
                        "tool_calls": tool_calls
                    }
                    
        except Exception as e:
            logger.error(f"Ollama completion error: {e}")
            raise
    
    async def _openai_completion(
        self,
        messages: List[Dict[str, Any]],
        tools: Optional[List[Dict[str, Any]]],
        tool_choice: str
    ) -> Dict[str, Any]:
        """OpenAI-compatible completion implementation."""
        import aiohttp
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens
        }
        
        if tools:
            payload["tools"] = tools
            payload["tool_choice"] = tool_choice
        
        headers = {
            "Content-Type": "application/json"
        }
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/v1/chat/completions",
                    json=payload,
                    headers=headers,
                    timeout=aiohttp.ClientTimeout(total=60)
                ) as response:
                    if response.status != 200:
                        error_text = await response.text()
                        raise RuntimeError(f"OpenAI API error: {error_text}")
                    
                    result = await response.json()
                    choice = result["choices"][0]
                    message = choice["message"]
                    
                    return {
                        "content": message.get("content", ""),
                        "tool_calls": message.get("tool_calls")
                    }
                    
        except Exception as e:
            logger.error(f"OpenAI completion error: {e}")
            raise
    
    def _create_tool_prompt(self, tools: List[Dict[str, Any]]) -> str:
        """Create a prompt describing available tools."""
        tool_descriptions = []
        for tool in tools:
            name = tool["name"]
            desc = tool["description"]
            params = tool.get("parameters", {}).get("properties", {})
            required = tool.get("parameters", {}).get("required", [])
            
            param_desc = []
            for param_name, param_info in params.items():
                req_marker = " (required)" if param_name in required else " (optional)"
                param_desc.append(f"  - {param_name}: {param_info.get('description', '')}{req_marker}")
            
            tool_str = f"{name}: {desc}"
            if param_desc:
                tool_str += "\n" + "\n".join(param_desc)
            
            tool_descriptions.append(tool_str)
        
        return f"""Available Tools:
{chr(10).join(tool_descriptions)}

To use a tool, respond with a JSON object in this format:
{{"tool": "tool_name", "arguments": {{"param1": "value1", "param2": "value2"}}}}

If you don't need to use a tool, just respond normally."""
    
    def _parse_tool_calls_from_text(
        self,
        text: str,
        tools: List[Dict[str, Any]]
    ) -> Optional[List[Dict[str, Any]]]:
        """Parse tool calls from LLM text response."""
        # Try to find JSON in the response
        json_pattern = r'\{[^{}]*"tool"[^{}]*\}'
        matches = re.findall(json_pattern, text)
        
        if not matches:
            return None
        
        try:
            # Parse the first JSON match
            tool_call_data = json.loads(matches[0])
            tool_name = tool_call_data.get("tool")
            arguments = tool_call_data.get("arguments", {})
            
            # Validate tool name
            valid_tools = [t["name"] for t in tools]
            if tool_name not in valid_tools:
                return None
            
            return [{
                "id": "call_1",
                "type": "function",
                "name": tool_name,
                "arguments": arguments
            }]
            
        except json.JSONDecodeError:
            logger.warning("Failed to parse tool call JSON from response")
            return None


class AgenticBrowser:
    """
    Agentic Browser that uses LLM for intelligent web browsing.
    Implements a perception-reasoning-action loop.
    """
    
    # Tool definitions for the LLM
    TOOLS = [
        {
            "name": "navigate",
            "description": "Navigate to a specific URL in the browser. Always include the full URL with protocol (https://)",
            "parameters": {
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "The URL to navigate to (must include protocol, e.g., https://)"
                    }
                },
                "required": ["url"]
            }
        },
        {
            "name": "read_page",
            "description": "Extract and read the text content from the current page. Returns the page title and main text content. Use this to understand what's on the page.",
            "parameters": {
                "type": "object",
                "properties": {
                    "selector": {
                        "type": "string",
                        "description": "Optional CSS selector to read specific elements. If not provided, reads the entire page."
                    }
                },
                "required": []
            }
        },
        {
            "name": "screenshot",
            "description": "Take a screenshot of the current page or a specific element and save it to a file",
            "parameters": {
                "type": "object",
                "properties": {
                    "filename": {
                        "type": "string",
                        "description": "Filename to save the screenshot (e.g., 'screenshot.png')"
                    },
                    "selector": {
                        "type": "string",
                        "description": "Optional CSS selector to screenshot a specific element. If not provided, screenshots the entire page."
                    },
                    "full_page": {
                        "type": "boolean",
                        "description": "Whether to capture the full scrollable page (default: False)"
                    }
                },
                "required": ["filename"]
            }
        },
        {
            "name": "complete",
            "description": "Mark the task as complete and provide the final answer or summary",
            "parameters": {
                "type": "object",
                "properties": {
                    "answer": {
                        "type": "string",
                        "description": "The final answer or summary of what was accomplished"
                    }
                },
                "required": ["answer"]
            }
        }
    ]
    
    def __init__(
        self,
        model: str = "mistral",
        headless: bool = True,
        max_iterations: int = 15,
        base_url: str = "http://localhost:11434",
        api_type: str = "ollama",
        api_key: Optional[str] = None
    ):
        """
        Initialize the Agentic Browser.
        
        Args:
            model: LLM model name (e.g., "mistral", "llama2", "gpt-4")
            headless: Run browser in headless mode
            max_iterations: Maximum number of perception-reasoning-action loops
            base_url: Base URL for LLM API
            api_type: Type of LLM API ("ollama", "openai")
            api_key: API key for remote LLM services
        """
        from browser.automation import BrowserController
        
        self.llm = LLMClient(
            model=model,
            base_url=base_url,
            api_type=api_type,
            api_key=api_key
        )
        self.browser = BrowserController(headless=headless)
        self.max_iterations = max_iterations
        self.conversation_history: List[Dict[str, Any]] = []
        self.current_url: Optional[str] = None
        self._browser_started = False
        
    async def run(self, goal: str) -> Dict[str, Any]:
        """
        Execute the main perception-reasoning-action loop.
        
        Args:
            goal: The high-level goal/task for the agent to accomplish
            
        Returns:
            Dict containing the final result and execution summary
        """
        logger.info(f"Starting Agentic Browser with goal: {goal}")
        
        # Initialize conversation with the goal
        self.conversation_history = [
            {
                "role": "system",
                "content": self._get_system_prompt()
            },
            {
                "role": "user",
                "content": f"Goal: {goal}\n\nPlease accomplish this goal by using the available tools. Think step by step and explain your reasoning."
            }
        ]
        
        iteration = 0
        final_result = None
        
        while iteration < self.max_iterations:
            iteration += 1
            logger.info(f"Starting iteration {iteration}/{self.max_iterations}")
            
            # PERCEPTION: Get current state
            perception = await self._perceive()
            
            # REASONING: Get LLM decision on next action
            action_decision = await self._reason(perception)
            
            if action_decision.get("type") == "complete":
                logger.info("Agent has completed the task")
                final_result = action_decision.get("result")
                break
            
            # ACTION: Execute the decided action
            if action_decision.get("type") == "tool_call":
                tool_result = await self._act(action_decision)
                
                # Add tool result to conversation history
                self.conversation_history.append({
                    "role": "assistant",
                    "content": action_decision.get("reasoning", ""),
                    "tool_calls": [action_decision.get("tool_call")]
                })
                self.conversation_history.append({
                    "role": "tool",
                    "content": json.dumps({
                        "success": tool_result.success,
                        "result": str(tool_result.result)[:1000],  # Limit result size
                        "error": tool_result.error
                    })
                })
            else:
                logger.warning(f"Unknown action type: {action_decision.get('type')}")
                break
        
        if iteration >= self.max_iterations:
            logger.warning("Reached maximum iterations without completing the goal")
            
        return {
            "success": final_result is not None,
            "result": final_result,
            "iterations": iteration,
            "conversation_history": self.conversation_history
        }
    
    def _get_system_prompt(self) -> str:
        """Get the system prompt for the LLM."""
        return """You are an intelligent web browsing agent. Your job is to accomplish user goals by navigating and interacting with web pages.

You have access to the following tools:
1. navigate(url) - Navigate to a URL
2. read_page(selector=None) - Read text content from the current page
3. screenshot(filename, selector=None, full_page=False) - Take a screenshot

For each step:
1. Analyze the current state and what you've learned so far
2. Decide on the next action to take
3. Use the appropriate tool
4. Observe the results and continue

When you've completed the goal, respond with a summary of what you accomplished.
Always explain your reasoning before taking an action."""
    
    async def _perceive(self) -> Dict[str, Any]:
        """
        Perception phase: Gather information about current state.
        
        Returns:
            Dict containing current state information
        """
        perception = {
            "current_url": self.current_url,
            "iteration": len([m for m in self.conversation_history if m.get("role") == "assistant"])
        }
        
        # If we have a page loaded, get basic info
        if self.current_url:
            try:
                page_info = await self.browser.get_page_info()
                perception["page_title"] = page_info.get("title", "")
                perception["page_ready"] = page_info.get("ready", False)
            except Exception as e:
                logger.error(f"Error getting page info: {e}")
                perception["error"] = str(e)
        
        return perception
    
    async def _reason(self, perception: Dict[str, Any]) -> Dict[str, Any]:
        """
        Reasoning phase: Use LLM to decide next action.
        
        Args:
            perception: Current state information
            
        Returns:
            Dict containing the action decision
        """
        # Add perception context if meaningful
        if perception.get("current_url"):
            context_msg = f"\nCurrent state: On page '{perception.get('page_title', 'Unknown')}' at {perception['current_url']}"
            self.conversation_history.append({
                "role": "system",
                "content": context_msg
            })
        
        try:
            # Call LLM with tool definitions
            response = await self.llm.chat_completion(
                messages=self.conversation_history,
                tools=self.TOOLS,
                tool_choice="auto"
            )
            
            # Parse LLM response
            if response.get("tool_calls"):
                tool_call = response["tool_calls"][0]
                return {
                    "type": "tool_call",
                    "reasoning": response.get("content", ""),
                    "tool_call": tool_call
                }
            else:
                # No tool call means the agent thinks it's done
                return {
                    "type": "complete",
                    "result": response.get("content", "Task completed")
                }
                
        except Exception as e:
            logger.error(f"Error in reasoning phase: {e}")
            return {
                "type": "error",
                "error": str(e)
            }
    
    async def _act(self, action_decision: Dict[str, Any]) -> ToolResult:
        """
        Action phase: Execute the decided tool/action.
        
        Args:
            action_decision: The decision from the reasoning phase
            
        Returns:
            ToolResult with execution results
        """
        tool_call = action_decision.get("tool_call", {})
        tool_name = tool_call.get("name")
        tool_args = tool_call.get("arguments", {})
        
        if isinstance(tool_args, str):
            tool_args = json.loads(tool_args)
        
        logger.info(f"Executing tool: {tool_name} with args: {tool_args}")
        
        try:
            if tool_name == "navigate":
                result = await self._tool_navigate(tool_args)
            elif tool_name == "read_page":
                result = await self._tool_read_page(tool_args)
            elif tool_name == "screenshot":
                result = await self._tool_screenshot(tool_args)
            else:
                return ToolResult(
                    tool_name=tool_name,
                    success=False,
                    result=None,
                    error=f"Unknown tool: {tool_name}"
                )
            
            return ToolResult(
                tool_name=tool_name,
                success=True,
                result=result
            )
            
        except Exception as e:
            logger.error(f"Error executing tool {tool_name}: {e}")
            return ToolResult(
                tool_name=tool_name,
                success=False,
                result=None,
                error=str(e)
            )
    
    async def _tool_navigate(self, args: Dict[str, Any]) -> str:
        """Execute navigate tool."""
        url = args["url"]
        await self.browser.navigate(url)
        self.current_url = url
        logger.info(f"Navigated to: {url}")
        return f"Successfully navigated to {url}"
    
    async def _tool_read_page(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute read_page tool."""
        selector = args.get("selector")
        content = await self.browser.get_content(selector=selector)
        logger.info(f"Read page content (length: {len(str(content))})")
        return content
    
    async def _tool_screenshot(self, args: Dict[str, Any]) -> str:
        """Execute screenshot tool."""
        filename = args["filename"]
        selector = args.get("selector")
        full_page = args.get("full_page", False)
        
        path = await self.browser.screenshot(
            filename=filename,
            selector=selector,
            full_page=full_page
        )
        logger.info(f"Screenshot saved to: {path}")
        return f"Screenshot saved to {path}"
