// Comet AI Browser Chat - Main JavaScript

class CometChat {
    constructor() {
        this.chatMessages = document.getElementById('chat-messages');
        this.chatInput = document.getElementById('chat-input');
        this.sendButton = document.getElementById('send-button');
        this.modelSelector = document.getElementById('model-selector');
        this.currentModelSpan = document.getElementById('current-model');
        this.statusDot = document.getElementById('status-dot');
        this.statusText = document.getElementById('status-text');
        
        // Settings
        this.settings = {
            ollamaUrl: 'http://localhost:11434',
            apiUrl: 'http://localhost:5000',
            autoExecute: true,
            showThinking: true,
            browserControlPermission: null // null = not asked, true = allowed, false = denied
        };
        
        // Chat history
        this.messages = [];
        this.currentModel = 'llama2';
        
        // Initialize
        this.init();
    }
    
    init() {
        this.loadSettings();
        this.attachEventListeners();
        this.checkOllamaStatus();
        this.loadChatHistory();
        
        // Auto-resize textarea
        this.chatInput.addEventListener('input', () => {
            this.chatInput.style.height = 'auto';
            this.chatInput.style.height = this.chatInput.scrollHeight + 'px';
        });
    }
    
    attachEventListeners() {
        // Send message
        this.sendButton.addEventListener('click', () => this.sendMessage());
        this.chatInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.sendMessage();
            }
        });
        
        // Model selection
        this.modelSelector.addEventListener('change', (e) => {
            this.currentModel = e.target.value;
            this.currentModelSpan.textContent = e.target.options[e.target.selectedIndex].text;
            this.saveSettings();
        });
        
        // Quick commands
        document.querySelectorAll('.quick-cmd').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.chatInput.value = e.target.dataset.command;
                this.sendMessage();
            });
        });
        
        // Clear chat
        document.getElementById('clear-chat').addEventListener('click', () => {
            if (confirm('Clear all chat history?')) {
                this.clearChat();
            }
        });
        
        // Settings modal
        document.getElementById('settings-button').addEventListener('click', () => {
            this.openSettings();
        });
        
        document.getElementById('close-settings').addEventListener('click', () => {
            this.closeSettings();
        });
        
        document.getElementById('save-settings').addEventListener('click', () => {
            this.saveSettingsFromModal();
        });
        
        // Temperature slider
        document.getElementById('temperature').addEventListener('input', (e) => {
            document.getElementById('temp-value').textContent = e.target.value;
        });
        
        // Close modal on outside click
        document.getElementById('settings-modal').addEventListener('click', (e) => {
            if (e.target.id === 'settings-modal') {
                this.closeSettings();
            }
        });
    }
    
    async sendMessage() {
        const message = this.chatInput.value.trim();
        if (!message) return;
        
        // Clear input
        this.chatInput.value = '';
        this.chatInput.style.height = 'auto';
        
        // Remove welcome message if exists
        const welcomeMsg = document.querySelector('.welcome-message');
        if (welcomeMsg) {
            welcomeMsg.remove();
        }
        
        // Add user message
        this.addMessage('user', message);
        
        // Show thinking indicator
        const thinkingId = this.showThinking();
        
        try {
            // Check if it's a browser command
            const commandResult = await this.detectAndExecuteCommand(message);
            
            // Get AI response
            const response = await this.getAIResponse(message, commandResult);
            
            // Remove thinking indicator
            this.removeThinking(thinkingId);
            
            // Add AI response
            this.addMessage('ai', response);
            
            // If permission was denied, add helpful message
            if (commandResult && commandResult.permissionDenied) {
                this.addMessage('system', 'Browser control was denied. You can change this in Settings or grant permission when prompted again.', 'warning');
            }
            
        } catch (error) {
            this.removeThinking(thinkingId);
            this.addMessage('system', `Error: ${error.message}`, 'error');
            this.updateStatus('error', 'Error occurred');
        }
        
        // Save chat history
        this.saveChatHistory();
    }
    
    async detectAndExecuteCommand(message) {
        const lowerMsg = message.toLowerCase();
        
        // Command patterns
        const commands = {
            browse: /(?:browse to|go to|open|navigate to)\s+(.+)/i,
            search: /(?:search for|google|find)\s+(.+)/i,
            click: /(?:click|press|tap)\s+(?:on\s+)?(.+)/i,
            screenshot: /(?:take|capture)\s+(?:a\s+)?screenshot/i,
            scroll: /scroll\s+(up|down|to\s+.+)/i,
            type: /type\s+["'](.+)["']/i,
            back: /go back|navigate back/i,
            forward: /go forward|navigate forward/i,
            refresh: /refresh|reload/i
        };
        
        let commandResult = null;
        
        for (const [type, pattern] of Object.entries(commands)) {
            const match = message.match(pattern);
            if (match) {
                // Check for browser control permission
                if (this.settings.browserControlPermission === null) {
                    // First time - ask for permission
                    const granted = await this.requestBrowserControlPermission(type, match[1] || null);
                    if (!granted) {
                        return {
                            type,
                            detected: true,
                            permissionDenied: true,
                            parameter: match[1] || null
                        };
                    }
                } else if (this.settings.browserControlPermission === false) {
                    // Permission was previously denied
                    return {
                        type,
                        detected: true,
                        permissionDenied: true,
                        parameter: match[1] || null
                    };
                }
                
                // Permission granted - execute if auto-execute is on
                if (this.settings.autoExecute) {
                    commandResult = await this.executeCommand(type, match[1] || null);
                } else {
                    commandResult = {
                        type,
                        detected: true,
                        autoExecute: false,
                        parameter: match[1] || null
                    };
                }
                break;
            }
        }
        
        return commandResult;
    }
    
    async requestBrowserControlPermission(commandType, parameter) {
        return new Promise((resolve) => {
            // Create permission dialog
            const dialog = this.createPermissionDialog(commandType, parameter);
            document.body.appendChild(dialog);
            
            // Handle allow button
            dialog.querySelector('#allow-control').addEventListener('click', () => {
                this.settings.browserControlPermission = true;
                this.saveSettings();
                dialog.remove();
                resolve(true);
            });
            
            // Handle deny button
            dialog.querySelector('#deny-control').addEventListener('click', () => {
                this.settings.browserControlPermission = false;
                this.saveSettings();
                dialog.remove();
                resolve(false);
            });
            
            // Handle allow once button
            dialog.querySelector('#allow-once').addEventListener('click', () => {
                dialog.remove();
                resolve(true);
            });
        });
    }
    
    createPermissionDialog(commandType, parameter) {
        const dialog = document.createElement('div');
        dialog.className = 'permission-dialog';
        dialog.innerHTML = `
            <div class="permission-content">
                <div class="permission-header">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 1L3 5V11C3 16.55 6.84 21.74 12 23C17.16 21.74 21 16.55 21 11V5L12 1Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M9 12L11 14L15 10" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                    <h2>Browser Control Permission</h2>
                </div>
                <div class="permission-body">
                    <p>Comet AI wants to control your browser to execute:</p>
                    <div class="permission-command">
                        <strong>${commandType.toUpperCase()}</strong>
                        ${parameter ? `<span>${parameter}</span>` : ''}
                    </div>
                    <p class="permission-warning">⚠️ This will allow the AI to interact with web pages on your behalf.</p>
                </div>
                <div class="permission-actions">
                    <button id="deny-control" class="secondary-button">Deny</button>
                    <button id="allow-once" class="secondary-button">Allow Once</button>
                    <button id="allow-control" class="primary-button">Always Allow</button>
                </div>
            </div>
        `;
        return dialog;
    }
    
    async executeCommand(type, parameter) {
        const commandId = Date.now();
        const commandElement = this.addCommandExecution(type, parameter, commandId);
        
        try {
            const response = await fetch(`${this.settings.apiUrl}/execute`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    command: type,
                    parameter: parameter
                })
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const result = await response.json();
            this.updateCommandExecution(commandId, 'success', result.message || 'Command executed successfully');
            
            return {
                type,
                executed: true,
                success: true,
                result: result.message
            };
            
        } catch (error) {
            this.updateCommandExecution(commandId, 'error', error.message);
            return {
                type,
                executed: true,
                success: false,
                error: error.message
            };
        }
    }
    
    async getAIResponse(userMessage, commandResult) {
        try {
            // Build context
            let context = userMessage;
            if (commandResult) {
                context = `User request: ${userMessage}\n\nCommand execution result: ${JSON.stringify(commandResult)}`;
            }
            
            // Call Ollama API
            const response = await fetch(`${this.settings.ollamaUrl}/api/generate`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    model: this.currentModel,
                    prompt: this.buildPrompt(context),
                    stream: false,
                    options: {
                        temperature: this.settings.temperature
                    }
                })
            });
            
            if (!response.ok) {
                throw new Error('Ollama API request failed');
            }
            
            const data = await response.json();
            return data.response;
            
        } catch (error) {
            // Fallback to simple response if Ollama is not available
            console.error('Ollama error:', error);
            
            if (commandResult && commandResult.executed) {
                return commandResult.success 
                    ? `✅ Command executed successfully: ${commandResult.result}`
                    : `❌ Command failed: ${commandResult.error}`;
            }
            
            return "I apologize, but I'm having trouble connecting to the AI model. Please make sure Ollama is running on your system.";
        }
    }
    
    buildPrompt(userMessage) {
        // Build conversation context
        const recentMessages = this.messages.slice(-6); // Last 3 exchanges
        let conversationContext = '';
        
        for (const msg of recentMessages) {
            if (msg.role === 'user') {
                conversationContext += `User: ${msg.content}\n`;
            } else if (msg.role === 'ai') {
                conversationContext += `Assistant: ${msg.content}\n`;
            }
        }
        
        // System prompt
        const systemPrompt = `You are Comet AI, an intelligent browser assistant. You help users browse the web, search for information, and automate browser tasks. 
        
When users ask you to perform browser actions, acknowledge the action and provide helpful context or suggestions.

Key capabilities:
- Browse to websites
- Search for information
- Click elements
- Take screenshots
- Scroll pages
- Type text
- Navigate history

Be concise, helpful, and friendly. Use markdown formatting when appropriate.`;
        
        return `${systemPrompt}\n\n${conversationContext}\nUser: ${userMessage}\nAssistant:`;
    }
    
    addMessage(role, content, type = null) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role}`;
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.textContent = role === 'user' ? 'U' : role === 'ai' ? 'AI' : 'S';
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        const header = document.createElement('div');
        header.className = 'message-header';
        
        const author = document.createElement('span');
        author.className = 'message-author';
        author.textContent = role === 'user' ? 'You' : role === 'ai' ? 'Comet AI' : 'System';
        
        const time = document.createElement('span');
        time.className = 'message-time';
        time.textContent = new Date().toLocaleTimeString();
        
        header.appendChild(author);
        header.appendChild(time);
        
        const text = document.createElement('div');
        text.className = 'message-text';
        
        // Render markdown for AI responses
        if (role === 'ai') {
            text.innerHTML = DOMPurify.sanitize(marked.parse(content));
            // Highlight code blocks
            text.querySelectorAll('pre code').forEach((block) => {
                hljs.highlightElement(block);
            });
        } else {
            text.textContent = content;
        }
        
        contentDiv.appendChild(header);
        contentDiv.appendChild(text);
        
        messageDiv.appendChild(avatar);
        messageDiv.appendChild(contentDiv);
        
        this.chatMessages.appendChild(messageDiv);
        this.scrollToBottom();
        
        // Save to history
        this.messages.push({
            role,
            content,
            timestamp: Date.now()
        });
    }
    
    showThinking() {
        const thinkingId = `thinking-${Date.now()}`;
        const thinkingDiv = document.createElement('div');
        thinkingDiv.id = thinkingId;
        thinkingDiv.className = 'message ai';
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.textContent = 'AI';
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        const thinking = document.createElement('div');
        thinking.className = 'thinking';
        thinking.innerHTML = '<div class="thinking-dot"></div><div class="thinking-dot"></div><div class="thinking-dot"></div>';
        
        contentDiv.appendChild(thinking);
        thinkingDiv.appendChild(avatar);
        thinkingDiv.appendChild(contentDiv);
        
        this.chatMessages.appendChild(thinkingDiv);
        this.scrollToBottom();
        
        return thinkingId;
    }
    
    removeThinking(thinkingId) {
        const element = document.getElementById(thinkingId);
        if (element) {
            element.remove();
        }
    }
    
    addCommandExecution(type, parameter, commandId) {
        const cmdDiv = document.createElement('div');
        cmdDiv.className = 'command-execution';
        cmdDiv.id = `command-${commandId}`;
        
        const header = document.createElement('div');
        header.className = 'command-header';
        
        const status = document.createElement('div');
        status.className = 'command-status';
        status.innerHTML = '<div class="status-spinner"></div><span>Executing...</span>';
        
        const code = document.createElement('div');
        code.className = 'command-code';
        code.textContent = `${type}${parameter ? `: ${parameter}` : ''}`;
        
        header.appendChild(status);
        header.appendChild(code);
        cmdDiv.appendChild(header);
        
        // Add to last message or create new system message
        const lastMessage = this.chatMessages.lastElementChild;
        if (lastMessage && lastMessage.classList.contains('user')) {
            const content = lastMessage.querySelector('.message-content .message-text');
            content.appendChild(cmdDiv);
        } else {
            const systemMsg = document.createElement('div');
            systemMsg.className = 'message system';
            
            const avatar = document.createElement('div');
            avatar.className = 'message-avatar';
            avatar.textContent = 'S';
            
            const contentDiv = document.createElement('div');
            contentDiv.className = 'message-content';
            contentDiv.appendChild(cmdDiv);
            
            systemMsg.appendChild(avatar);
            systemMsg.appendChild(contentDiv);
            this.chatMessages.appendChild(systemMsg);
        }
        
        this.scrollToBottom();
        return cmdDiv;
    }
    
    updateCommandExecution(commandId, status, message) {
        const cmdDiv = document.getElementById(`command-${commandId}`);
        if (!cmdDiv) return;
        
        const statusDiv = cmdDiv.querySelector('.command-status');
        const resultDiv = document.createElement('div');
        resultDiv.className = `command-result ${status}`;
        resultDiv.textContent = message;
        
        if (status === 'success') {
            statusDiv.innerHTML = '<span>✅ Success</span>';
        } else {
            statusDiv.innerHTML = '<span>❌ Failed</span>';
        }
        
        cmdDiv.appendChild(resultDiv);
    }
    
    scrollToBottom() {
        this.chatMessages.scrollTop = this.chatMessages.scrollHeight;
    }
    
    clearChat() {
        this.chatMessages.innerHTML = '';
        this.messages = [];
        this.saveChatHistory();
        
        // Re-add welcome message
        this.chatMessages.innerHTML = `
            <div class="welcome-message">
                <div class="welcome-icon">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 2L2 7L12 12L22 7L12 2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M2 17L12 22L22 17" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M2 12L12 17L22 12" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </div>
                <h2>Welcome to Comet AI Browser</h2>
                <p>Your intelligent browsing assistant powered by local LLMs</p>
                <div class="quick-commands">
                    <h3>Try these commands:</h3>
                    <button class="quick-cmd" data-command="Browse to https://github.com">Browse to GitHub</button>
        // Check if user wants to reset browser control permission
        const resetPermission = document.getElementById('reset-permission');
        if (resetPermission && resetPermission.checked) {
            this.settings.browserControlPermission = null;
        }
        
                    <button class="quick-cmd" data-command="Search for AI news">Search for AI news</button>
                    <button class="quick-cmd" data-command="Take a screenshot">Take a screenshot</button>
                    <button class="quick-cmd" data-command="Summarize this page">Summarize this page</button>
                </div>
            </div>
        `;
        
        // Re-attach quick command listeners
        document.querySelectorAll('.quick-cmd').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.chatInput.value = e.target.dataset.command;
                this.sendMessage();
            });
        });
    }
    
    async checkOllamaStatus() {
        try {
            const response = await fetch(`${this.settings.ollamaUrl}/api/tags`);
            if (response.ok) {
                const data = await response.json();
                this.updateStatus('success', `Ready (${data.models?.length || 0} models)`);
                
                // Update model selector with available models
                if (data.models && data.models.length > 0) {
                    this.updateModelSelector(data.models);
                }
            } else {
                this.updateStatus('warning', 'Ollama not responding');
            }
        } catch (error) {
            this.updateStatus('error', 'Ollama not available');
        }
    }
    
    updateModelSelector(models) {
        // Keep current selection
        const currentValue = this.modelSelector.value;
        
        // Clear and rebuild
        this.modelSelector.innerHTML = '';
        
        models.forEach(model => {
            const option = document.createElement('option');
            option.value = model.name;
            option.textContent = model.name;
            this.modelSelector.appendChild(option);
        });
        
        // Restore selection if still available
        if (Array.from(this.modelSelector.options).some(opt => opt.value === currentValue)) {
            this.modelSelector.value = currentValue;
        } else if (models.length > 0) {
            this.currentModel = models[0].name;
            this.currentModelSpan.textContent = models[0].name;
        }
    }
    
    updateStatus(status, text) {
        this.statusDot.className = `status-dot ${status}`;
        this.statusText.textContent = text;
    }
    
        
        // Update permission status display
        const permissionStatus = document.getElementById('permission-status');
        if (permissionStatus) {
            if (this.settings.browserControlPermission === true) {
                permissionStatus.textContent = '✅ Allowed';
                permissionStatus.className = 'permission-status allowed';
            } else if (this.settings.browserControlPermission === false) {
                permissionStatus.textContent = '❌ Denied';
                permissionStatus.className = 'permission-status denied';
            } else {
                permissionStatus.textContent = '⏸️ Not Set';
                permissionStatus.className = 'permission-status not-set';
            }
        }
    openSettings() {
        const modal = document.getElementById('settings-modal');
        modal.classList.add('active');
        
        // Populate current settings
        document.getElementById('ollama-url').value = this.settings.ollamaUrl;
        document.getElementById('api-url').value = this.settings.apiUrl;
        document.getElementById('auto-execute').checked = this.settings.autoExecute;
        document.getElementById('show-thinking').checked = this.settings.showThinking;
        document.getElementById('temperature').value = this.settings.temperature;
        document.getElementById('temp-value').textContent = this.settings.temperature;
    }
    
    closeSettings() {
        const modal = document.getElementById('settings-modal');
        modal.classList.remove('active');
    }
    
    saveSettingsFromModal() {
        this.settings.ollamaUrl = document.getElementById('ollama-url').value;
        this.settings.apiUrl = document.getElementById('api-url').value;
        this.settings.autoExecute = document.getElementById('auto-execute').checked;
        this.settings.showThinking = document.getElementById('show-thinking').checked;
        this.settings.temperature = parseFloat(document.getElementById('temperature').value);
        
        this.saveSettings();
        this.closeSettings();
        
        // Recheck Ollama status with new URL
        this.checkOllamaStatus();
    }
    
    saveSettings() {
        localStorage.setItem('cometSettings', JSON.stringify(this.settings));
        localStorage.setItem('cometModel', this.currentModel);
    }
    
    loadSettings() {
        const savedSettings = localStorage.getItem('cometSettings');
        if (savedSettings) {
            this.settings = { ...this.settings, ...JSON.parse(savedSettings) };
        }
        
        const savedModel = localStorage.getItem('cometModel');
        if (savedModel) {
            this.currentModel = savedModel;
            this.modelSelector.value = savedModel;
            
            // Update display
            const selectedOption = this.modelSelector.options[this.modelSelector.selectedIndex];
            if (selectedOption) {
                this.currentModelSpan.textContent = selectedOption.text;
            }
        }
    }
    
    saveChatHistory() {
        localStorage.setItem('cometChatHistory', JSON.stringify(this.messages));
    }
    
    loadChatHistory() {
        const savedHistory = localStorage.getItem('cometChatHistory');
        if (savedHistory) {
            try {
                this.messages = JSON.parse(savedHistory);
                
                // Restore messages to UI
                if (this.messages.length > 0) {
                    // Remove welcome message
                    const welcomeMsg = document.querySelector('.welcome-message');
                    if (welcomeMsg) {
                        welcomeMsg.remove();
                    }
                    
                    // Add all messages
                    this.messages.forEach(msg => {
                        this.addMessageToUI(msg.role, msg.content, msg.timestamp);
                    });
                }
            } catch (error) {
                console.error('Failed to load chat history:', error);
            }
        }
    }
    
    addMessageToUI(role, content, timestamp) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${role}`;
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.textContent = role === 'user' ? 'U' : role === 'ai' ? 'AI' : 'S';
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        
        const header = document.createElement('div');
        header.className = 'message-header';
        
        const author = document.createElement('span');
        author.className = 'message-author';
        author.textContent = role === 'user' ? 'You' : role === 'ai' ? 'Comet AI' : 'System';
        
        const time = document.createElement('span');
        time.className = 'message-time';
        time.textContent = new Date(timestamp).toLocaleTimeString();
        
        header.appendChild(author);
        header.appendChild(time);
        
        const text = document.createElement('div');
        text.className = 'message-text';
        
        // Render markdown for AI responses
        if (role === 'ai') {
            text.innerHTML = DOMPurify.sanitize(marked.parse(content));
            // Highlight code blocks
            text.querySelectorAll('pre code').forEach((block) => {
                hljs.highlightElement(block);
            });
        } else {
            text.textContent = content;
        }
        
        contentDiv.appendChild(header);
        contentDiv.appendChild(text);
        
        messageDiv.appendChild(avatar);
        messageDiv.appendChild(contentDiv);
        
        this.chatMessages.appendChild(messageDiv);
    }
}

// Initialize chat when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.cometChat = new CometChat();
});
