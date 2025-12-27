#!/usr/bin/env python3
"""
Test script to verify the Agentic Browser implementation
"""

import asyncio
import sys
from pathlib import Path


async def test_llm_client():
    """Test the LLM client independently"""
    print("\n" + "="*60)
    print("TEST 1: LLM Client")
    print("="*60)
    
    from agent.core import LLMClient
    
    client = LLMClient(model="mistral", api_type="ollama")
    
    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Say 'Hello, World!' and nothing else."}
    ]
    
    try:
        response = await client.chat_completion(messages)
        print(f"✅ LLM Response: {response.get('content', '')[:100]}")
        return True
    except Exception as e:
        print(f"❌ LLM Client Error: {e}")
        return False


async def test_browser_controller():
    """Test the browser controller independently"""
    print("\n" + "="*60)
    print("TEST 2: Browser Controller")
    print("="*60)
    
    from browser.automation import BrowserController
    
    async with BrowserController(headless=True) as browser:
        try:
            # Test navigation
            print("  Testing navigation...")
            result = await browser.navigate("https://example.com")
            print(f"  ✅ Navigation: {result.get('success')}")
            
            # Test content reading
            print("  Testing content reading...")
            content = await browser.get_content()
            print(f"  ✅ Content: {len(content.get('content', ''))} chars, title='{content.get('title', '')}'")
            
            # Test screenshot
            print("  Testing screenshot...")
            path = await browser.screenshot("test_screenshot.png")
            print(f"  ✅ Screenshot: {path}")
            
            return True
        except Exception as e:
            print(f"  ❌ Browser Error: {e}")
            return False


async def test_agentic_browser():
    """Test the full agentic browser"""
    print("\n" + "="*60)
    print("TEST 3: Agentic Browser (Full Integration)")
    print("="*60)
    
    from agent.core import AgenticBrowser
    
    async with AgenticBrowser(model="mistral", headless=True, max_iterations=5) as agent:
        try:
            result = await agent.run("Navigate to example.com and tell me the page title")
            
            print(f"\n  Success: {result.get('success')}")
            print(f"  Iterations: {result.get('iterations')}")
            print(f"  Result: {result.get('result', '')[:200]}")
            
            return result.get('success', False)
        except Exception as e:
            print(f"  ❌ Agentic Browser Error: {e}")
            import traceback
            traceback.print_exc()
            return False


async def test_tool_parsing():
    """Test tool call parsing"""
    print("\n" + "="*60)
    print("TEST 4: Tool Call Parsing")
    print("="*60)
    
    from agent.core import LLMClient
    
    client = LLMClient(model="mistral", api_type="ollama")
    
    tools = [
        {
            "name": "test_tool",
            "description": "A test tool",
            "parameters": {
                "type": "object",
                "properties": {
                    "arg1": {"type": "string", "description": "Test argument"}
                },
                "required": ["arg1"]
            }
        }
    ]
    
    # Test text with tool call
    test_text = '''I will use the tool. {"tool": "test_tool", "arguments": {"arg1": "test_value"}}'''
    
    tool_calls = client._parse_tool_calls_from_text(test_text, tools)
    
    if tool_calls:
        print(f"  ✅ Parsed tool calls: {tool_calls}")
        return True
    else:
        print(f"  ❌ Failed to parse tool calls")
        return False


async def main():
    """Run all tests"""
    print("\n🧪 Comet Agentic Browser - Test Suite")
    print("="*60)
    print("This will test all components of the agentic browser")
    print("="*60)
    
    # Check prerequisites
    print("\n📋 Prerequisites Check:")
    print("  - Python: ✅")
    print("  - Playwright: ", end="")
    try:
        import playwright
        print("✅")
    except ImportError:
        print("❌ (run: pip install playwright)")
        return
    
    print("  - aiohttp: ", end="")
    try:
        import aiohttp
        print("✅")
    except ImportError:
        print("❌ (run: pip install aiohttp)")
        return
    
    # Run tests
    results = {}
    
    # Test 1: LLM Client
    results['llm_client'] = await test_llm_client()
    
    # Test 2: Browser Controller (independent of LLM)
    results['browser'] = await test_browser_controller()
    
    # Test 3: Tool Parsing
    results['tool_parsing'] = await test_tool_parsing()
    
    # Test 4: Full Integration (requires both LLM and Browser)
    if results['llm_client'] and results['browser']:
        results['integration'] = await test_agentic_browser()
    else:
        print("\n⚠️  Skipping integration test due to component failures")
        results['integration'] = False
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    for test_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {test_name}: {status}")
    
    total = len(results)
    passed = sum(results.values())
    print(f"\n  Total: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n  🎉 All tests passed!")
    else:
        print("\n  ⚠️  Some tests failed. Check the output above.")
    
    return passed == total


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
