import { useState, useEffect } from 'react';
import './App.css';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';

function App() {
  const [messages, setMessages] = useState([]);
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Fetch messages
      const messagesRes = await fetch(`${API_URL}/api/messages`);
      const messagesData = await messagesRes.json();

      // Fetch health status
      const healthRes = await fetch(`${API_URL}/api/health`);
      const healthData = await healthRes.json();

      setMessages(messagesData.data || []);
      setHealth(healthData);
    } catch (err) {
      setError('Failed to connect to backend. Make sure the backend server is running on port 5000.');
      console.error('Error fetching data:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>🚀 DevOps Demo Application</h1>
        <p className="subtitle">React Frontend + Express Backend</p>
      </header>

      <main className="app-main">
        {loading && (
          <div className="loading">
            <div className="spinner"></div>
            <p>Connecting to backend...</p>
          </div>
        )}

        {error && (
          <div className="error-card">
            <h3>⚠️ Connection Error</h3>
            <p>{error}</p>
            <button onClick={fetchData} className="retry-btn">
              🔄 Retry Connection
            </button>
          </div>
        )}

        {!loading && !error && (
          <>
            <section className="health-section">
              <h2>Backend Health Status</h2>
              <div className="health-card">
                <div className="health-item">
                  <span className="label">Status:</span>
                  <span className={`status ${health?.status}`}>
                    {health?.status === 'healthy' ? '✅' : '❌'} {health?.status}
                  </span>
                </div>
                <div className="health-item">
                  <span className="label">Uptime:</span>
                  <span className="value">{Math.floor(health?.uptime || 0)}s</span>
                </div>
                <div className="health-item">
                  <span className="label">Last Check:</span>
                  <span className="value">
                    {health?.timestamp ? new Date(health.timestamp).toLocaleTimeString() : 'N/A'}
                  </span>
                </div>
              </div>
            </section>

            <section className="messages-section">
              <h2>Messages from Backend</h2>
              <div className="messages-grid">
                {messages.map((message) => (
                  <div key={message.id} className="message-card">
                    <div className="message-id">#{message.id}</div>
                    <p className="message-text">{message.text}</p>
                    <div className="message-time">
                      {new Date(message.timestamp).toLocaleString()}
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section className="info-section">
              <div className="info-card">
                <h3>🏗️ Architecture</h3>
                <ul>
                  <li><strong>Frontend:</strong> React + Vite</li>
                  <li><strong>Backend:</strong> Express.js</li>
                  <li><strong>Communication:</strong> REST API</li>
                  <li><strong>Containerization:</strong> Docker (Coming Soon)</li>
                  <li><strong>Deployment:</strong> AWS (S3 + EC2)</li>
                </ul>
              </div>
            </section>
          </>
        )}
      </main>

      <footer className="app-footer">
        <p>DevOps Demo Project | Microservices Architecture</p>
      </footer>
    </div>
  );
}

export default App;
