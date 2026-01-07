import { useState, useRef, useEffect } from 'react';
import './AskArvashu.css';
import arvashuBot from '../assets/Arvashu-bot.png';

const AskArvashu = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [conversationId] = useState(`user-${Date.now()}`); // Generate unique conversation ID
  const messagesEndRef = useRef(null);

  // Auto-scroll to bottom when new messages arrive
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!inputValue.trim() || isLoading) return;

    const userMessage = {
      role: 'user',
      content: inputValue,
      timestamp: new Date().toISOString()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);

    try {
      // Try localhost first
      let apiUrl = 'https://healthassistant.vaardesigns.com';
      let response;

      try {
        response = await fetch(`${apiUrl}/query`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ 
            conversation_id: conversationId,
            question: inputValue 
          }),
          signal: AbortSignal.timeout(50000) // 5 second timeout for localhost
        });
      } catch (localError) {
        // If localhost fails, try AWS
        console.log('Localhost failed, trying AWS endpoint...');
        apiUrl = 'https://healthassistant.vaardesigns.com';
        response = await fetch(`${apiUrl}/query`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ 
            conversation_id: conversationId,
            question: inputValue 
          })
        });
      }

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      const assistantMessage = {
        role: 'assistant',
        content: data.response || data.answer || data.message || 'No response received',
        timestamp: new Date().toISOString()
      };

      setMessages(prev => [...prev, assistantMessage]);
    } catch (error) {
      console.error('Error calling API:', error);
      const errorMessage = {
        role: 'assistant',
        content: `Sorry, I encountered an error: ${error.message}. Please try again later.`,
        timestamp: new Date().toISOString(),
        isError: true
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const toggleChat = () => {
    setIsOpen(!isOpen);
  };

  const clearChat = () => {
    setMessages([]);
  };

  return (
    <div className="ask-arvashu-container">
      {/* Chat Window */}
      {isOpen && (
        <div className="chat-window">
          <div className="chat-header">
            <div className="chat-header-content">
              <img src={arvashuBot} alt="Arvashu Bot" className="chat-avatar" />
              <div>
                <h3>Ask Arvashu</h3>
                <p className="chat-subtitle">Your AI Assistant</p>
              </div>
            </div>
            <div className="chat-header-actions">
              {messages.length > 0 && (
                <button 
                  className="clear-btn" 
                  onClick={clearChat}
                  title="Clear chat"
                >
                  🗑️
                </button>
              )}
              <button 
                className="close-btn" 
                onClick={toggleChat}
                title="Close chat"
              >
                ✕
              </button>
            </div>
          </div>

          <div className="chat-messages">
            {messages.length === 0 ? (
              <div className="welcome-message">
                <h4>👋 Hello! I'm Arvashu</h4>
                <p>How can I assist you today?</p>
              </div>
            ) : (
              messages.map((message, index) => (
                <div 
                  key={index} 
                  className={`message ${message.role} ${message.isError ? 'error' : ''}`}
                >
                  <div className="message-content">
                    {message.content}
                  </div>
                  <div className="message-timestamp">
                    {new Date(message.timestamp).toLocaleTimeString([], { 
                      hour: '2-digit', 
                      minute: '2-digit' 
                    })}
                  </div>
                </div>
              ))
            )}
            {isLoading && (
              <div className="message assistant loading">
                <div className="message-content">
                  <div className="typing-indicator">
                    <span></span>
                    <span></span>
                    <span></span>
                  </div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <form className="chat-input-form" onSubmit={handleSubmit}>
            <input
              type="text"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              placeholder="Type your question here..."
              className="chat-input"
              disabled={isLoading}
            />
            <button 
              type="submit" 
              className="send-btn"
              disabled={isLoading || !inputValue.trim()}
            >
              {isLoading ? '...' : '➤'}
            </button>
          </form>
        </div>
      )}

      {/* Toggle Button */}
      <button 
        className={`chat-toggle-btn ${isOpen ? 'open' : ''}`}
        onClick={toggleChat}
        title="Ask Arvashu"
      >
        {isOpen ? (
          <span className="close-icon">✕</span>
        ) : (
          <img src={arvashuBot} alt="Ask Arvashu" className="toggle-avatar" />
        )}
      </button>
    </div>
  );
};

export default AskArvashu;
