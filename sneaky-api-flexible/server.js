const express = require('express');
const cors = require('cors');
const config = require('./config');
const routes = require('./routes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Routes
app.use('/api', routes);

// Error handler
app.use(errorHandler);

// Start server
app.listen(config.port, () => {
    console.log('\n' + '='.repeat(60));
    console.log('🚀 Sneaky API Flexible Server Started');
    console.log('='.repeat(60));
    console.log(`Environment: ${config.nodeEnv}`);
    console.log(`Port: ${config.port}`);
    console.log(`URL: http://localhost:${config.port}`);
    console.log('\n📚 Available Endpoints:');
    console.log(`  GET  /api/health`);
    console.log(`  POST /api/text                  - Text only`);
    console.log(`  POST /api/analyze               - Auto-detect image source`);
    console.log(`  POST /api/analyze/base64        - Image as base64`);
    console.log(`  POST /api/analyze/upload        - Upload image file`);
    console.log(`  POST /api/analyze/path          - Image file path`);
    console.log(`  POST /api/analyze/latest        - Latest from Downloads`);
    console.log(`  GET  /api/downloads/latest      - Get latest download info`);
    console.log(`  POST /api/cleanup               - Cleanup temp files`);
    console.log('='.repeat(60) + '\n');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('\nSIGINT received, shutting down gracefully...');
    process.exit(0);
});
