const http = require('http');
const fs = require('fs');

const BASE_URL = 'localhost';
const PORT = 3000;

function makeRequest(endpoint, method, data) {
    return new Promise((resolve, reject) => {
        const payload = JSON.stringify(data);

        const options = {
            hostname: BASE_URL,
            port: PORT,
            path: endpoint,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': payload.length
            }
        };

        const req = http.request(options, (res) => {
            let responseData = '';

            res.on('data', (chunk) => {
                responseData += chunk;
            });

            res.on('end', () => {
                try {
                    resolve(JSON.parse(responseData));
                } catch (e) {
                    resolve(responseData);
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        req.write(payload);
        req.end();
    });
}

async function testAllEndpoints() {
    console.log('\n' + '='.repeat(60));
    console.log('Testing Sneaky API Flexible');
    console.log('='.repeat(60) + '\n');

    try {
        // Test 1: Health check
        console.log('1. Testing health endpoint...');
        const health = await makeRequest('/api/health', 'GET', {});
        console.log('✓ Health:', health);
        console.log('');

        // Test 2: Text only
        console.log('2. Testing text-only endpoint...');
        const textResult = await makeRequest('/api/text', 'POST', {
            prompt: 'What is artificial intelligence in one sentence?'
        });
        console.log('✓ Text Response:', textResult.response?.substring(0, 100) + '...');
        console.log('');

        // Test 3: Base64 image (if you have a test image)
        if (fs.existsSync('./test-image.jpg')) {
            console.log('3. Testing base64 image endpoint...');
            const imageBuffer = fs.readFileSync('./test-image.jpg');
            const imageBase64 = imageBuffer.toString('base64');

            const base64Result = await makeRequest('/api/analyze/base64', 'POST', {
                prompt: 'What is in this image?',
                imageBase64: imageBase64,
                imageName: 'test.jpg'
            });
            console.log('✓ Base64 Response:', base64Result.response?.substring(0, 100) + '...');
            console.log('');
        }

        // Test 4: Image path
        if (fs.existsSync('./test-image.jpg')) {
            console.log('4. Testing image path endpoint...');
            const pathResult = await makeRequest('/api/analyze/path', 'POST', {
                prompt: 'Describe this image briefly',
                imagePath: './test-image.jpg'
            });
            console.log('✓ Path Response:', pathResult.response?.substring(0, 100) + '...');
            console.log('');
        }

        // Test 5: Latest from Downloads
        console.log('5. Testing latest downloads endpoint...');
        try {
            const latestResult = await makeRequest('/api/analyze/latest', 'POST', {
                prompt: 'What do you see in this image?'
            });
            console.log('✓ Latest Response:', latestResult.response?.substring(0, 100) + '...');
        } catch (e) {
            console.log('⚠ Latest downloads test skipped (no images found)');
        }
        console.log('');

        // Test 6: Get latest image info
        console.log('6. Testing get latest download info...');
        try {
            const latestInfo = await makeRequest('/api/downloads/latest', 'GET', {});
            console.log('✓ Latest Image Info:', latestInfo);
        } catch (e) {
            console.log('⚠ No images in Downloads folder');
        }
        console.log('');

        console.log('='.repeat(60));
        console.log('All tests completed!');
        console.log('='.repeat(60) + '\n');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

// Run tests
testAllEndpoints();
