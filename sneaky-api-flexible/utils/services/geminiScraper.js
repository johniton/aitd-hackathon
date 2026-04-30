const https = require('https');
const fs = require('fs');
const ImageHelper = require('../imageHelper');

const GROQ_API_KEY = process.env.GROQ_API_KEY || '';

function groqRequest(prompt, base64Image, mimeType) {
    return new Promise((resolve, reject) => {
        const messages = base64Image
            ? [{
                role: 'user',
                content: [
                    { type: 'image_url', image_url: { url: `data:${mimeType};base64,${base64Image}` } },
                    { type: 'text', text: prompt }
                ]
              }]
            : [{ role: 'user', content: prompt }];

        const body = JSON.stringify({
            model: 'meta-llama/llama-4-scout-17b-16e-instruct',
            messages,
            max_tokens: 1024,
        });

        const options = {
            hostname: 'api.groq.com',
            path: '/openai/v1/chat/completions',
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${GROQ_API_KEY}`,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(body),
            },
        };

        const req = https.request(options, (res) => {
            let raw = '';
            res.on('data', chunk => raw += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(raw);
                    if (res.statusCode !== 200) {
                        return reject(new Error(`Groq error ${res.statusCode}: ${raw}`));
                    }
                    const text = parsed?.choices?.[0]?.message?.content;
                    if (!text) return reject(new Error('Empty response from Groq'));
                    resolve(text);
                } catch (e) {
                    reject(new Error(`Failed to parse response: ${e.message}`));
                }
            });
        });

        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

class GeminiScraper {
    async scrape(prompt, options = {}) {
        const { imagePath = null, imageBuffer = null, useLatestDownload = false } = options;

        let finalBuffer = null;
        let tempFile = null;
        let mimeType = 'image/jpeg';

        try {
            if (imageBuffer) {
                finalBuffer = imageBuffer;
            } else if (imagePath) {
                if (!fs.existsSync(imagePath)) throw new Error(`Image not found: ${imagePath}`);
                finalBuffer = fs.readFileSync(imagePath);
            } else if (useLatestDownload) {
                const latest = ImageHelper.getLatestImageFromDownloads();
                finalBuffer = fs.readFileSync(latest.path);
            }

            const imageName = options.imageName || 'image.jpg';
            if (imageName.toLowerCase().endsWith('.png')) mimeType = 'image/png';
            else if (imageName.toLowerCase().endsWith('.webp')) mimeType = 'image/webp';

            const base64Image = finalBuffer ? finalBuffer.toString('base64') : null;

            console.log('Calling Groq vision...');
            const response = await groqRequest(prompt, base64Image, mimeType);
            console.log('Response received.');

            if (tempFile) ImageHelper.deleteFile(tempFile);

            return {
                success: true,
                prompt,
                response: response.trim(),
                imageUsed: !!finalBuffer,
                timestamp: new Date().toISOString(),
            };

        } catch (error) {
            if (tempFile) ImageHelper.deleteFile(tempFile);
            throw error;
        }
    }
}

module.exports = new GeminiScraper();
