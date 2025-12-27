#!/usr/bin/env python3
"""
Comet Agentic Browser - Main Entry Point
An open-source AI agentic browser with Chromium and local LLMs
"""

import asyncio
import sys
from agent.core import AgenticBrowser


async def main():
    """Main function to run the agentic browser"""
    print("🤖 Comet Agentic Browser")
    print("=" * 60)
    print("An AI-powered web browser using LLMs for intelligent automation")
    print("=" * 60)
    print()
    
    # Get task from command line or use default
    if len(sys.argv) > 1:
        task = " ".join(sys.argv[1:])
    else:
        task = "Go to example.com and tell me what you see on the page"
    
    print(f"📋 Task: {task}")
    print("-" * 60)
    print()
    
    # Initialize the browser agent
    async with AgenticBrowser(
        model="mistral",
        headless=True,
        max_iterations=15
    ) as agent:
        try:
            result = await agent.run(task)
            
            print()
            print("=" * 60)
            print("📊 FINAL RESULT")
            print("=" * 60)
            print(f"✅ Success: {result['success']}")
            print(f"🔄 Iterations: {result['iterations']}")
            print(f"📝 Result:\n{result['result']}")
            print("=" * 60)
            
        except KeyboardInterrupt:
            print("\n\n⚠️  Task interrupted by user")
        except Exception as e:
            print(f"\n\n❌ Error: {e}")
            import traceback
            traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
