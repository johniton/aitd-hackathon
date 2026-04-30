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

    // Detect available browser
    let browserChannel = undefined;
    let executablePath = undefined;

    // Try to find Chrome first, then fall back to Chromium
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
            '--disable-features=IsolateOrigins,site-per-process',
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-web-security',
            '--disable-features=VizDisplayCompositor',
            '--disable-dev-shm-usage',
            '--disable-background-timer-throttling',
            '--disable-backgrounding-occluded-windows',
            '--disable-renderer-backgrounding',
            '--disable-infobars',
            '--window-size=1920,1080',
            '--start-maximized',
            '--disable-extensions',
            '--disable-default-apps',
            '--no-first-run',
            '--no-zygote',
            '--disable-accelerated-2d-canvas',
            '--disable-gpu'
        ],
        viewport: { width: 1920, height: 1080 },
        userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        locale: 'en-US',
        timezoneId: 'Asia/Kolkata',
        ignoreDefaultArgs: ['--enable-automation', '--enable-blink-features=AutomationControlled'],
        bypassCSP: true,
        permissions: [],
        extraHTTPHeaders: {
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        }
    });

    const page = browser.pages()[0] || await browser.newPage();

    // Enhanced stealth scripts
    await page.addInitScript(() => {
        // Remove webdriver completely
        delete Object.getPrototypeOf(navigator).webdriver;

        Object.defineProperty(navigator, 'webdriver', {
            get: () => undefined,
            configurable: true
        });

        // Mock hardware concurrency
        Object.defineProperty(navigator, 'hardwareConcurrency', {
            get: () => 8
        });

        // Mock device memory
        Object.defineProperty(navigator, 'deviceMemory', {
            get: () => 8
        });

        // Mock plugins with realistic values
        Object.defineProperty(navigator, 'plugins', {
            get: () => {
                return Object.create(PluginArray.prototype, {
                    length: { value: 3 },
                    0: { value: { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer', description: 'Portable Document Format' } },
                    1: { value: { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai', description: 'Portable Document Format' } },
                    2: { value: { name: 'Native Client', filename: 'internal-nacl-plugin', description: 'Native Client Executable' } }
                });
            }
        });

        // Mock mimeTypes
        Object.defineProperty(navigator, 'mimeTypes', {
            get: () => {
                return Object.create(MimeTypeArray.prototype, {
                    length: { value: 2 },
                    0: { value: { type: 'application/pdf', suffixes: 'pdf', description: 'Portable Document Format' } },
                    1: { value: { type: 'application/x-nacl', suffixes: '', description: 'Native Client Executable' } }
                });
            }
        });

        // Mock languages
        Object.defineProperty(navigator, 'languages', {
            get: () => ['en-US', 'en']
        });

        // Add chrome object
        window.chrome = {
            runtime: {
                OnInstalledReason: {
                    CHROME_UPDATE: "chrome_update",
                    INSTALL: "install",
                    SHARED_MODULE_UPDATE: "shared_module_update",
                    UPDATE: "update"
                },
                OnRestartRequiredReason: {
                    APP_UPDATE: "app_update",
                    OS_UPDATE: "os_update",
                    PERIODIC: "periodic"
                },
                PlatformArch: {
                    ARM: "arm",
                    ARM64: "arm64",
                    MIPS: "mips",
                    MIPS64: "mips64",
                    X86_32: "x86-32",
                    X86_64: "x86-64"
                },
                PlatformNaclArch: {
                    ARM: "arm",
                    MIPS: "mips",
                    MIPS64: "mips64",
                    X86_32: "x86-32",
                    X86_64: "x86-64"
                },
                PlatformOs: {
                    ANDROID: "android",
                    CROS: "cros",
                    LINUX: "linux",
                    MAC: "mac",
                    OPENBSD: "openbsd",
                    WIN: "win"
                },
                RequestUpdateCheckStatus: {
                    NO_UPDATE: "no_update",
                    THROTTLED: "throttled",
                    UPDATE_AVAILABLE: "update_available"
                }
            },
            loadTimes: function() { },
            csi: function() { },
            app: {}
        };

        // Override permissions
        const originalQuery = window.navigator.permissions.query;
        window.navigator.permissions.query = (parameters) => (
            parameters.name === 'notifications' ?
                Promise.resolve({ state: Notification.permission }) :
                originalQuery(parameters)
        );

        // Hide that we modified toString
        const originalToString = Function.prototype.toString;
        const newToString = function toString() {
            if (this === window.navigator.permissions.query) {
                return 'function query() { [native code] }';
            }
            if (this === newToString) {
                return originalToString.toString();
            }
            return originalToString.call(this);
        };
        Function.prototype.toString = newToString;

        // Mock battery API
        if (!navigator.getBattery) {
            navigator.getBattery = () => Promise.resolve({
                charging: true,
                chargingTime: 0,
                dischargingTime: Infinity,
                level: 1,
                addEventListener: () => { },
                removeEventListener: () => { },
                dispatchEvent: () => true
            });
        }

        // Mock connection
        Object.defineProperty(navigator, 'connection', {
            get: () => ({
                effectiveType: '4g',
                rtt: 50,
                downlink: 10,
                saveData: false
            })
        });
    });

    try {
        console.log('\nNavigating to Google...');
        await page.goto('https://accounts.google.com/', {
            waitUntil: 'domcontentloaded',
            timeout: 60000
        });

        console.log('\n' + '='.repeat(60));
        console.log('MANUAL LOGIN REQUIRED');
        console.log('='.repeat(60));
        console.log('\nInstructions:');
        console.log('1. Complete Google login in the browser window');
        console.log('2. After successful login, go to: https://gemini.google.com');
        console.log('3. Wait for Gemini chat interface to load completely');
        console.log('4. Come back here and press ENTER to save session\n');
        console.log('TIP: If you see "browser may not be secure", try:');
        console.log('  - Use Incognito/Guest mode option if available');
        console.log('  - Or click "Try to sign in anyway" if prompted\n');

        await new Promise((resolve) => {
            process.stdin.once('data', resolve);
        });

        console.log('\nSaving session state...');
        const storagePath = path.resolve(profileDir, 'state.json');

        const storageState = await page.context().storageState();
        fs.writeFileSync(storagePath, JSON.stringify(storageState, null, 2));

        console.log('✓ Session saved at:', storagePath);
        console.log('✓ Browser profile at:', userDataDir);
        console.log('\nReady! Run your scraper with:');
        console.log('  node index.js "Your prompt here"');
        console.log('  node index.js "Explain quantum computing" --visible\n');

    } catch (error) {
        console.error('Error:', error.message);
    } finally {
        await browser.close();
        process.exit(0);
    }
})();
