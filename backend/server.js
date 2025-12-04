const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Sample data
const messages = [
  { id: 1, text: 'Welcome to the DevOps Demo!', timestamp: new Date().toISOString() },
  { id: 2, text: 'This is a microservices architecture', timestamp: new Date().toISOString() },
  { id: 3, text: 'Backend powered by Express.js', timestamp: new Date().toISOString() },
];

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'DevOps Demo API is running!' });
});

app.get('/api/messages', (req, res) => {
  res.json({ success: true, data: messages });
});

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Backend server running on port ${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/api/health`);
  console.log(`📨 Messages API: http://localhost:${PORT}/api/messages`);
});
