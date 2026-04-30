function validateTextPrompt(req, res, next) {
    const { prompt } = req.body;

    if (!prompt || typeof prompt !== 'string' || prompt.trim().length === 0) {
        return res.status(400).json({
            success: false,
            error: 'prompt is required and must be a non-empty string'
        });
    }

    req.body.prompt = prompt.trim();
    next();
}

function validateImageAnalysis(req, res, next) {
    const { prompt, imageBase64, imageUrl, imagePath, useLatestDownload } = req.body;

    if (!prompt || typeof prompt !== 'string' || prompt.trim().length === 0) {
        return res.status(400).json({
            success: false,
            error: 'prompt is required and must be a non-empty string'
        });
    }

    // Check if at least one image source is provided
    const hasImageSource = imageBase64 || imageUrl || imagePath || useLatestDownload || req.file;

    if (!hasImageSource) {
        return res.status(400).json({
            success: false,
            error: 'At least one image source is required: imageBase64, imageUrl, imagePath, useLatestDownload, or file upload'
        });
    }

    req.body.prompt = prompt.trim();
    next();
}

module.exports = {
    validateTextPrompt,
    validateImageAnalysis
};
