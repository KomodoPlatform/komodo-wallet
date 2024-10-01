// @ts-check
// Use ES module import syntax to import functionality from the module
// that we have compiled.
//
// Note that the `default` import is an initialization function which
// will "boot" the module and make it ready to use. Currently browsers
// don't support natively imported WebAssembly as an ES module, but
// eventually the manual initialization won't be required!
import init, { LogLevel, Mm2MainErr, Mm2RpcErr, mm2_main, mm2_main_status, mm2_rpc, mm2_version } from "./src/mm2/kdflib.js";
import './services/theme_checker/theme_checker.js';
import zip from './services/zip/zip.js';

const LOG_LEVEL = LogLevel.Info;

// Loads the wasm file, so we use the
// default export to inform it where the wasm file is located on the
// server, and then we wait on the returned promise to wait for the
// wasm to be loaded.
// @ts-ignore
window.init_wasm = async function () {
    await init();
}

// @ts-ignore
window.run_mm2 = async function (params, handle_log) {
    let config = {
        conf: JSON.parse(params),
        log_level: LOG_LEVEL,
    }

    // run an MM2 instance
    try {
        mm2_main(config, handle_log);
    } catch (e) {
        switch (e) {
            case Mm2MainErr.AlreadyRuns:
                alert("MM2 already runs, please wait...");
                break;
            case Mm2MainErr.InvalidParams:
                alert("Invalid config");
                break;
            case Mm2MainErr.NoCoinsInConf:
                alert("No 'coins' field in config");
                break;
            default:
                alert(`Oops: ${e}`);
                break;
        }
        handle_log(LogLevel.Error, JSON.stringify(e))
    }
}
// @ts-ignore
window.rpc_request = async function (request_js) {
    try {
        let reqJson = JSON.parse(request_js);
        const response = await mm2_rpc(reqJson);
        return JSON.stringify(response);
    } catch (e) {
        switch (e) {
            case Mm2RpcErr.NotRunning:
                alert("MM2 is not running yet");
                break;
            case Mm2RpcErr.InvalidPayload:
                alert(`Invalid payload: ${request_js}`);
                break;
            case Mm2RpcErr.InternalError:
                alert(`An MM2 internal error`);
                break;
            default:
                alert(`Unexpected error: ${e}`);
                break;
        }
        throw (e);
    }
}


// @ts-ignore
window.mm2_version = () => mm2_version().result;

// @ts-ignore
window.mm2_status = function () {
    return mm2_main_status();
}
// @ts-ignore
window.reload_page = function () {
    window.location.reload();
}

// @ts-ignore
window.zip_encode = zip.encode;