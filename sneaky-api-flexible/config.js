require('dotenv').config();
const path = require('path');
const os = require('os');

module.exports = {
    port: process.env.PORT || 3000,
    nodeEnv: process.env.NODE_ENV || 'development',
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 10485760, // 10MB
    tempDir: path.resolve(__dirname, process.env.TEMP_DIR || 'temp'),
    uploadsDir: path.resolve(__dirname, process.env.UPLOADS_DIR || 'uploads'),
    downloadsPath: process.env.DOWNLOADS_PATH
        ? process.env.DOWNLOADS_PATH.replace('~', os.homedir())
        : path.join(os.homedir(), 'Downloads'),
    browser: {
        headless: process.env.BROWSER_HEADLESS !== 'false',
        timeout: parseInt(process.env.BROWSER_TIMEOUT) || 120000
    },
    browserDataDir: path.resolve(__dirname, 'browser-data')
};

