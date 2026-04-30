const { chromium } = require('playwright');
const config = require('../config');

class BrowserHelper {
    static async getBrowserExecutable() {
        const chromePaths = [
            '/usr/bin/google-chrome-stable',
            '/usr/bin/google-chrome',
            '/usr/bin/chromium',
            '/usr/bin/chromium-browser'
        ];

        const fs = require('fs');
        for (const chromePath of chromePaths) {
            if (fs.existsSync(chromePath)) {
                return chromePath;
            }
        }
        return undefined;
    }

    static async createBrowserContext(headless = config.browser.headless) {
        const fs = require('fs');
        if (!fs.existsSync(config.browserDataDir)) {
            throw new Error('Browser profile not found. Run: npm run save-session');
        }

        const executablePath = await this.getBrowserExecutable();

        const browser = await chromium.launchPersistentContext(config.browserDataDir, {
            headless: headless,
            executablePath: executablePath,
            args: [
                '--disable-blink-features=AutomationControlled',
                '--disable-features=IsolateOrigins,site-per-process',
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-web-security',
                '--disable-dev-shm-usage',
                '--window-size=1920,1080'
            ],
            viewport: { width: 1920, height: 1080 },
            userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
            locale: 'en-US',
            timezoneId: 'Asia/Kolkata',
            ignoreDefaultArgs: ['--enable-automation'],
            bypassCSP: true,
            acceptDownloads: true
        });

        return browser;
    }

    static async addStealthScripts(page) {
        await page.addInitScript(() => {
            delete Object.getPrototypeOf(navigator).webdriver;
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined,
                configurable: true
            });

            Object.defineProperty(navigator, 'plugins', {
                get: () => Object.create(PluginArray.prototype, {
                    length: { value: 3 }
                })
            });

            Object.defineProperty(navigator, 'languages', {
                get: () => ['en-US', 'en']
            });

            window.chrome = {
                runtime: {},
                loadTimes: function() { },
                csi: function() { },
                app: {}
            };
        });
    }
}

module.exports = BrowserHelper;
