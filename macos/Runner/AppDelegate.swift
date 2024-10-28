import Cocoa
import FlutterMacOS

import os.log

var mm2StartArgs: String?
var eventSink: FlutterEventSink?

func mm2Callback(line: UnsafePointer<Int8>?) {
    if let lineStr = line, let sink = eventSink {
        let logMessage = String(cString: lineStr)
        sink(logMessage)
    }
}

@available(macOS 10.12, *)
func performMM2Start() -> Int32 {
    eventSink?("START MM2 --------------------------------")
    let error = Int32(mm2_main(mm2StartArgs, mm2Callback))
    eventSink?("START MM2 RESULT: \(error) ---------------")
    
    return error;
}
func performMM2Stop() -> Int32 {
    eventSink?("STOP MM2 --------------------------------");
    let error = Int32(mm2_stop());
    eventSink?("STOP MM2 RESULT: \(error) ---------------");
    return error;
}

@available(macOS 10.12, *)
@main
class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let channelMain = FlutterMethodChannel.init(name: "komodo-web-dex", binaryMessenger: controller.engine.binaryMessenger)
        
        let eventChannel = FlutterEventChannel(name: "komodo-web-dex/event", binaryMessenger: controller.engine.binaryMessenger)
        eventChannel.setStreamHandler(self)
        
        channelMain.setMethodCallHandler({
            (_ call: FlutterMethodCall, _ result: FlutterResult) -> Void in
            if ("start" == call.method) {
                guard let arg = (call.arguments as! Dictionary<String,String>)["params"] else { result(0); return }
                mm2StartArgs = arg;
                let error: Int32 = performMM2Start();
                
                result(error)
            } else if ("status" == call.method) {
                let ret = Int32(mm2_main_status());
                result(ret)
            } else if ("stop" == call.method) {
                let error: Int32 = performMM2Stop()
                result(error)
            }
        });
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
