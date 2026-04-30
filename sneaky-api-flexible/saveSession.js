const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
    console.log('Starting browser for manual login...');

    const profileDir = path.resolve(__dirname, 'gemini-profile');
    if (!fs.existsSync(profileDir)) {
        fs.mkdirSync(profileDir, { recursive: true });
    }

    const userDataDir = path.resolve(__dirname, 'browser-data');
    if (!fs.existsSync(userDataDir)) {
        fs.mkdirSync(userDataDir, { recursive: true });
    }

    let executablePath = undefined;
    const chromePaths = [
        '/usr/bin/google-chrome-stable',
        '/usr/bin/google-chrome',
        '/usr/bin/chromium',
        '/usr/bin/chromium-browser'
    ];

    for (const chromePath of chromePaths) {
        if (fs.existsSync(chromePath)) {
            executablePath = chromePath;
            console.log(`Using browser: ${chromePath}`);
            break;
        }
    }

    const browser = await chromium.launchPersistentContext(userDataDir, {
        headless: false,
        executablePath: executablePath,
        args: [
            '--disable-blink-features=AutomationControlled',
            '--no-sandbox',
            '--disable-setuid-sandbox'
        ],
        viewport: { width: 1920, height: 1080 },
        userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        ignoreDefaultArgs: ['--enable-automation']
    });

    const page = browser.pages()[0] || await browser.newPage();

    try {
        await page.goto('https://accounts.google.com/', { timeout: 60000 });
        console.log('\n' + '='.repeat(60));
        console.log('Complete login and press ENTER to save session...');
        console.log('='.repeat(60));
        await new Promise((resolve) => process.stdin.once('data', resolve));

        const storagePath = path.resolve(profileDir, 'state.json');
        const storageState = await page.context().storageState();
        fs.writeFileSync(storagePath, JSON.stringify(storageState, null, 2));

        console.log('✓ Session saved successfully!');
    } catch (error) {
        console.error('Error:', error.message);
    } finally {
        await browser.close();
        process.exit(0);
    }
})();

