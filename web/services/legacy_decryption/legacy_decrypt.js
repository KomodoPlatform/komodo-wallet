// Minimal web helper for legacy AtomicDEX desktop decryption using libsodium-wrappers
// Loads libsodium from CDN if not present and exposes two functions:
// - legacyDecrypt.decryptLegacySeedBase64(password, base64Cipher)
// - legacyDecrypt.isLegacyFormatBase64(base64Blob)
//
// Note: The desktop used crypto_pwhash with zeroed salt and secretstream xchacha20poly1305.
// We assume single-file with header + chunked ciphertext.

(function () {
    const legacyDecrypt = {};
    let sodiumReadyPromise = null;

    function ensureSodium() {
        if (typeof window.sodium !== 'undefined') {
            if (window.sodium.ready) {
                return window.sodium.ready.then(() => window.sodium);
            }
            return Promise.resolve(window.sodium);
        }
        if (sodiumReadyPromise) return sodiumReadyPromise;

        sodiumReadyPromise = new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = 'https://cdn.jsdelivr.net/npm/libsodium-wrappers@0.7.13/dist/libsodium-wrappers.min.js';
            script.async = true;
            script.onload = async () => {
                try {
                    await window.sodium.ready;
                    resolve(window.sodium);
                } catch (e) {
                    reject(e);
                }
            };
            script.onerror = (e) => reject(new Error('Failed to load libsodium-wrappers'));
            document.head.appendChild(script);
        });
        return sodiumReadyPromise;
    }

    function isLikelyLegacyBinary(bytes) {
        if (bytes.length < 24) return false;
        // Not JSON '{'
        if (bytes[0] === 123) return false;
        try {
            const text = new TextDecoder('utf-8', { fatal: false }).decode(bytes);
            if (text.startsWith('{')) return false;
            // base64? if decodes -> not legacy binary
            try {
                atob(text);
                return false;
            } catch (_) { }
            return true;
        } catch (_) {
            return true;
        }
    }

    legacyDecrypt.isLegacyFormatBase64 = function (b64) {
        try {
            const raw = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
            return isLikelyLegacyBinary(raw);
        } catch (_) {
            return false;
        }
    };

    legacyDecrypt.decryptLegacySeedBase64 = async function (password, b64Cipher) {
        const sodium = await ensureSodium();
        const data = Uint8Array.from(atob(b64Cipher), c => c.charCodeAt(0));
        if (data.length < sodium.crypto_secretstream_xchacha20poly1305_HEADERBYTES) return null;

        const header = data.subarray(0, sodium.crypto_secretstream_xchacha20poly1305_HEADERBYTES);
        const cipher = data.subarray(sodium.crypto_secretstream_xchacha20poly1305_HEADERBYTES);

        // Derive key with zero salt (legacy behavior)
        const salt = new Uint8Array(sodium.crypto_pwhash_SALTBYTES); // zeroed
        const key = sodium.crypto_pwhash(
            sodium.crypto_secretstream_xchacha20poly1305_KEYBYTES,
            password,
            salt,
            sodium.crypto_pwhash_OPSLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_MEMLIMIT_INTERACTIVE,
            sodium.crypto_pwhash_ALG_DEFAULT
        );

        const state = sodium.crypto_secretstream_xchacha20poly1305_init_pull(header, key);
        const chunkSize = 4096 + sodium.crypto_secretstream_xchacha20poly1305_ABYTES;
        let offset = 0;
        const out = [];
        while (offset < cipher.length) {
            const take = Math.min(chunkSize, cipher.length - offset);
            const chunk = cipher.subarray(offset, offset + take);
            const res = sodium.crypto_secretstream_xchacha20poly1305_pull(state, chunk);
            if (!res) return null;
            out.push(res.message);
            if (res.tag === sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL) break;
            offset += take;
        }
        const plain = sodium.to_string(sodium.concat(...out));
        return plain;
    };

    window.legacyDecrypt = legacyDecrypt;
})();


