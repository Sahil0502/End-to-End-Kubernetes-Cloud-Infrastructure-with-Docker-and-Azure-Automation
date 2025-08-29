const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Kubernetes Azure Infrastructure Demo!',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  res.json({
    service: 'k8s-azure-app',
    hostname: require('os').hostname(),
    platform: process.platform,
    nodeVersion: process.version,
    timestamp: new Date().toISOString()
  });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Health check available at http://localhost:${PORT}/health`);
});

module.exports = app;
