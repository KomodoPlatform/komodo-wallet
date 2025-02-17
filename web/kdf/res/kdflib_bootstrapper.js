// @ts-check
import init, { LogLevel } from "../kdf/bin/kdflib.js";
import * as kdflib from "../kdf/bin/kdflib.js";

const LOG_LEVEL = LogLevel.Info;

// Create a global 'kdf' object
const kdf = {};

// Initialization state
kdf._initPromise = null;
kdf._isInitializing = false;
kdf.isInitialized = false;

// Loads the wasm file, so we use the
// default export to inform it where the wasm file is located on the
// server, and then we wait on the returned promise to wait for the
// wasm to be loaded.
// @ts-ignore
kdf.init_wasm = async function () {
    if (kdf.isInitialized) {
        // If already initialized, return immediately
        return;
    }

    if (kdf._initPromise) {
        // If already initializing, await the existing promise
        return await kdf._initPromise;
    }
    if (kdf._isInitializing) {
        // If already initializing (but no promise yet), return a pending promise
        return new Promise((resolve, reject) => {
            const checkInitialization = () => {
                if (kdf._initPromise) {
                    kdf._initPromise.then(resolve).catch(reject);
                } else {
                    setTimeout(checkInitialization, 50);
                }
            };
            checkInitialization();
        });
    }

    kdf._isInitializing = true;
    kdf._initPromise = init()
        .then(() => {
            kdf._isInitializing = false;
            kdf._initPromise = null;
            kdf.isInitialized = true;
        })
        .catch((error) => {
            kdf._isInitializing = false;
            kdf._initPromise = null;
            throw error;
        });

    return await kdf._initPromise;
}



// @ts-ignore
kdf.reload_page = function () {
    window.location.reload();
}

// @ts-ignore
// kdf.zip_encode = zip.encode;


Object.assign(kdf, kdflib);

kdf.init_wasm().catch(console.error);

// @ts-ignore
window.kdf = kdf;

export default kdf;
export { kdf };
