#!/usr/bin/env python3
"""
Example script demonstrating the Agentic Browser usage
"""

import asyncio
from agent.core import AgenticBrowser, browse


async def example1():
    """Example 1: Using the AgenticBrowser class directly"""
    print("=" * 60)
    print("Example 1: Direct usage with context manager")
    print("=" * 60)
    
    async with AgenticBrowser(model="mistral", headless=True) as agent:
        result = await agent.run("Go to example.com and tell me what you see")
        
        print("\n" + "=" * 60)
        print("RESULT:")
        print("=" * 60)
        print(f"Success: {result['success']}")
        print(f"Iterations: {result['iterations']}")
        print(f"Result: {result['result']}")


async def example2():
    """Example 2: Using the convenience function"""
    print("\n" + "=" * 60)
    print("Example 2: Using convenience function")
    print("=" * 60)
    
    result = await browse(
        goal="Navigate to httpbin.org and read the main page content",
        model="mistral",
        headless=True
    )
    
    print("\n" + "=" * 60)
    print("RESULT:")
    print("=" * 60)
    print(f"Success: {result['success']}")
    print(f"Result: {result['result']}")


async def example3():
    """Example 3: Manual browser lifecycle management"""
    print("\n" + "=" * 60)
    print("Example 3: Manual lifecycle management")
    print("=" * 60)
    
    agent = AgenticBrowser(model="mistral", headless=True)
    
    try:
        await agent.start()
        result = await agent.run("Go to perplexity.ai and describe what you see")
        
        print("\n" + "=" * 60)
        print("RESULT:")
        print("=" * 60)
        print(f"Success: {result['success']}")
        print(f"Result: {result['result']}")
        
    finally:
        await agent.close()


async def main():
    """Run all examples"""
    print("\n🤖 Comet Agentic Browser - Examples")
    print("=" * 60)
    print("Note: Make sure Ollama is running with mistral model")
    print("  $ ollama run mistral")
    print("=" * 60)
    
    # Choose which example to run
    # await example1()
    await example2()
    # await example3()


if __name__ == "__main__":
    asyncio.run(main())
