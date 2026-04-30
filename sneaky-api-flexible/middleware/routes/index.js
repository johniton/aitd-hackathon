const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const geminiScraper = require('../../utils/services/geminiScraper');
const ImageHelper = require('../../utils/imageHelper');
const { validateTextPrompt, validateImageAnalysis } = require('../validateRequest');
const config = require('../../config');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        if (!fs.existsSync(config.uploadsDir)) {
            fs.mkdirSync(config.uploadsDir, { recursive: true });
        }
        cb(null, config.uploadsDir);
    },
    filename: (req, file, cb) => {
        const uniqueName = `${Date.now()}-${file.originalname}`;
        cb(null, uniqueName);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: config.maxFileSize },
    fileFilter: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        if (ImageHelper.validImageExtensions.includes(ext)) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed (jpg, jpeg, png, gif, webp)'));
        }
    }
});

// Health check
router.get('/health', (req, res) => {
    res.json({
        success: true,
        service: 'sneaky-api-flexible',
        status: 'running',
        timestamp: new Date().toISOString()
    });
});

// Text-only prompt
router.post('/text', validateTextPrompt, async (req, res, next) => {
    try {
        const { prompt, headless } = req.body;

        const result = await geminiScraper.scrape(prompt, {
            headless: headless !== false
        });

        res.json(result);
    } catch (error) {
        next(error);
    }
});

// Analyze with base64 image
router.post('/analyze/base64', validateImageAnalysis, async (req, res, next) => {
    try {
        const { prompt, imageBase64, imageName, headless } = req.body;

        const imageBuffer = ImageHelper.base64ToBuffer(imageBase64);

        const result = await geminiScraper.scrape(prompt, {
            imageBuffer: imageBuffer,
            imageName: imageName || 'image.jpg',
            headless: headless !== false
        });

        res.json(result);
    } catch (error) {
        next(error);
    }
});

// Analyze with file upload
router.post('/analyze/upload', upload.single('image'), async (req, res, next) => {
    try {
        const { prompt, headless } = req.body;

        if (!prompt) {
            return res.status(400).json({
                success: false,
                error: 'prompt is required'
            });
        }

        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'image file is required'
            });
        }

        const result = await geminiScraper.scrape(prompt, {
            imagePath: req.file.path,
            headless: headless !== 'false'
        });

        // Delete uploaded file after processing
        ImageHelper.deleteFile(req.file.path);

        res.json(result);
    } catch (error) {
        if (req.file) {
            ImageHelper.deleteFile(req.file.path);
        }
        next(error);
    }
});

// Analyze with image path
router.post('/analyze/path', validateImageAnalysis, async (req, res, next) => {
    try {
        const { prompt, imagePath, headless } = req.body;

        if (!imagePath) {
            return res.status(400).json({
                success: false,
                error: 'imagePath is required'
            });
        }

        const result = await geminiScraper.scrape(prompt, {
            imagePath: imagePath,
            headless: headless !== false
        });

        res.json(result);
    } catch (error) {
        next(error);
    }
});

// Analyze latest image from Downloads
router.post('/analyze/latest', validateTextPrompt, async (req, res, next) => {
    try {
        const { prompt, headless } = req.body;

        const result = await geminiScraper.scrape(prompt, {
            useLatestDownload: true,
            headless: headless !== false
        });

        res.json(result);
    } catch (error) {
        next(error);
    }
});

// Flexible analyze endpoint (auto-detects input type)
router.post('/analyze', async (req, res, next) => {
    try {
        const {
            prompt,
            imageBase64,
            imagePath,
            useLatestDownload,
            imageName,
            headless
        } = req.body;

        if (!prompt) {
            return res.status(400).json({
                success: false,
                error: 'prompt is required'
            });
        }

        let options = {
            headless: headless !== false
        };

        // Auto-detect image source
        if (useLatestDownload) {
            options.useLatestDownload = true;
        } else if (imageBase64) {
            options.imageBuffer = ImageHelper.base64ToBuffer(imageBase64);
            options.imageName = imageName || 'image.jpg';
        } else if (imagePath) {
            options.imagePath = imagePath;
        }

        const result = await geminiScraper.scrape(prompt, options);

        res.json(result);
    } catch (error) {
        next(error);
    }
});

// Get latest image info from Downloads
router.get('/downloads/latest', (req, res, next) => {
    try {
        const latestImage = ImageHelper.getLatestImageFromDownloads();

        res.json({
            success: true,
            image: {
                name: latestImage.name,
                path: latestImage.path,
                modified: latestImage.mtime
            }
        });
    } catch (error) {
        next(error);
    }
});

// Cleanup old temp files
router.post('/cleanup', (req, res) => {
    const { olderThanMinutes = 60 } = req.body;

    ImageHelper.cleanupTempFiles(olderThanMinutes);

    res.json({
        success: true,
        message: `Cleaned up temp files older than ${olderThanMinutes} minutes`
    });
});

module.exports = router;
