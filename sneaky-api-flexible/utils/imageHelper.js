const fs = require('fs');
const path = require('path');
const os = require('os');
const mime = require('mime-types');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');

class ImageHelper {
    static validImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

    static isValidImage(filePath) {
        const ext = path.extname(filePath).toLowerCase();
        return this.validImageExtensions.includes(ext);
    }

    static getLatestImageFromDownloads() {
        const downloadsPath = config.downloadsPath;

        if (!fs.existsSync(downloadsPath)) {
            throw new Error('Downloads folder not found');
        }

        const files = fs.readdirSync(downloadsPath);
        const imageFiles = files.filter(file => {
            const ext = path.extname(file).toLowerCase();
            return this.validImageExtensions.includes(ext);
        });

        if (imageFiles.length === 0) {
            throw new Error('No images found in Downloads folder');
        }

        const fileStats = imageFiles.map(file => {
            const filePath = path.join(downloadsPath, file);
            return {
                path: filePath,
                name: file,
                mtime: fs.statSync(filePath).mtime
            };
        });

        fileStats.sort((a, b) => b.mtime - a.mtime);
        return fileStats[0];
    }

    static saveBufferToTemp(buffer, originalName = null) {
        if (!fs.existsSync(config.tempDir)) {
            fs.mkdirSync(config.tempDir, { recursive: true });
        }

        const ext = originalName ? path.extname(originalName) : '.jpg';
        const filename = `${uuidv4()}${ext}`;
        const filePath = path.join(config.tempDir, filename);

        fs.writeFileSync(filePath, buffer);
        return filePath;
    }

    static deleteFile(filePath) {
        try {
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
                return true;
            }
        } catch (error) {
            console.error(`Failed to delete file: ${filePath}`, error);
        }
        return false;
    }

    static cleanupTempFiles(olderThanMinutes = 60) {
        if (!fs.existsSync(config.tempDir)) return;

        const files = fs.readdirSync(config.tempDir);
        const now = Date.now();
        const maxAge = olderThanMinutes * 60 * 1000;

        files.forEach(file => {
            const filePath = path.join(config.tempDir, file);
            const stats = fs.statSync(filePath);
            const age = now - stats.mtime.getTime();

            if (age > maxAge) {
                this.deleteFile(filePath);
                console.log(`Cleaned up old temp file: ${file}`);
            }
        });
    }

    static base64ToBuffer(base64String) {
        // Remove data URL prefix if present
        const base64Data = base64String.replace(/^data:image\/\w+;base64,/, '');
        return Buffer.from(base64Data, 'base64');
    }

    static bufferToBase64(buffer, mimeType = 'image/jpeg') {
        return `data:${mimeType};base64,${buffer.toString('base64')}`;
    }
}

module.exports = ImageHelper;
