import init, {
  LogLevel,
  Mm2MainErr,
  Mm2RpcErr,
  mm2_main,
  mm2_main_status,
  mm2_rpc,
  mm2_version,
} from "./src/mm2/mm2lib.js";

const LOG_LEVEL = LogLevel.Info;

let initialized = false;

async function init_wasm() {
  await init();
  initialized = true;
}

async function run_mm2(params, handle_log) {
  let config = {
    conf: JSON.parse(params),
    log_level: LOG_LEVEL,
  };

  // Run an MM2 instance
  try {
    mm2_main(config, handle_log);
  } catch (e) {
    switch (e) {
      case Mm2MainErr.AlreadyRuns:
        console.log("MM2 already runs, please wait...");
        break;
      case Mm2MainErr.InvalidParams:
        console.log("Invalid config");
        break;
      case Mm2MainErr.NoCoinsInConf:
        console.log("No 'coins' field in config");
        break;
      default:
        console.log(`Oops: ${e}`);
        break;
    }
    handle_log(LogLevel.Error, JSON.stringify(e));
  }
}

async function rpc_request(request_js) {
  try {
    let reqJson = JSON.parse(request_js);
    const response = await mm2_rpc(reqJson);
    return JSON.stringify(response);
  } catch (e) {
    switch (e) {
      case Mm2RpcErr.NotRunning:
        console.log("MM2 is not running yet");
        break;
      case Mm2RpcErr.InvalidPayload:
        console.log(`Invalid payload: ${request_js}`);
        break;
      case Mm2RpcErr.InternalError:
        console.log(`An MM2 internal error`);
        break;
      default:
        console.log(`Unexpected error: ${e}`);
        break;
    }
    throw e;
  }
}

// @ts-ignore
function get_mm2_version() {
  return mm2_version().result;
}

// @ts-ignore
function get_mm2_status() {
  if (!initialized) return 0;

  return mm2_main_status();
}

// Event listener for messages from the popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log(message.action + " called");

  if (message.action === "init_wasm") {
    init_wasm()
      .then(() => {
        console.log(message.action + " success");
        sendResponse({ success: true });
      })
      .catch((e) => {
        console.log(message.action + " fail");
        console.log(e);
        sendResponse({ success: false, error: e });
      });
  } else if (message.action === "run_mm2") {
    run_mm2(message.params, (level, message2) => {
      console.log(message.action + " callback");
      console.log(level);
      console.log(message2);
    })
      .then(() => {
        console.log(message.action + " success");
        sendResponse({ success: true });
      })
      .catch((e) => {
        console.log(message.action + " fail");
        console.log(e);
        sendResponse({ success: false, error: e });
      });
  } else if (message.action === "rpc_request") {
    rpc_request(message.request)
      .then((response) => {
        console.log("rpc_request, details:");
        console.log(message.request);
        console.log(message.action + " success, response:");
        console.log(response);
        sendResponse(response);
      })
      .catch((e) => {
        console.log(message.action + " fail");
        console.log(e);
        sendResponse({ success: false, error: e });
      });
  } else if (message.action === "version") {
    console.log(message.action + " success");
    try {
      sendResponse(get_mm2_version());
    } catch (e) {
      console.log(message.action + " fail");
      console.log(e);
      sendResponse({ success: false, error: e });
    }
  } else if (message.action === "mm2_status") {
    console.log(message.action + " success");
    try {
      sendResponse(get_mm2_status());
    } catch (e) {
      console.log(message.action + " fail");
      console.log(e);
      sendResponse({ success: false, error: e });
    }
  }

  return true;
});
