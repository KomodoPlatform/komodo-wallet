@JS()
library wasmlib;

import 'dart:js_interop';
import 'package:js/js.dart';

@JS('init_wasm')
external JSPromise<JSAny?> initWasm();

@JS('run_mm2')
external JSPromise<void> wasmRunMm2(JSString params, JSFunction handleLog);

@JS('mm2_status')
external int wasmMm2Status();

@JS('mm2_version')
external JSString wasmVersion();

@JS('rpc_request')
external JSPromise<JSAny?> wasmRpc(JSString request);

@JS('reload_page')
external void reloadPage();

@JS('changeTheme')
external void changeHtmlTheme(int themeIndex);

@JS('zip_encode')
external JSPromise<String?> zipEncode(JSString fileName, JSString fileContent);
