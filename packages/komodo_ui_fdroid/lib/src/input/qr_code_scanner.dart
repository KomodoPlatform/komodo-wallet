import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QrCodeReaderOverlay extends StatefulWidget {
  const QrCodeReaderOverlay({super.key});

  /// Shows the QR code reader overlay and returns the scanned QR code.
  ///
  /// Returns `null` if the user cancels the scan.
  static Future<String?> show(BuildContext context) async {
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const QrCodeReaderOverlay()),
    );
  }

  @override
  State<QrCodeReaderOverlay> createState() => _QrCodeReaderOverlayState();
}

class _QrCodeReaderOverlayState extends State<QrCodeReaderOverlay> {
  final GlobalKey debugKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _qrDetected = false;
  bool _controllerReady = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //TODO!:l10n title: Text(LocaleKeys.qrScannerTitle.tr()),
        title: const Text('QR Scanner'),
        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
        elevation: 0,
      ),
      body: Stack(
        children: [
          QRView(
            key: debugKey,
            onQRViewCreated: _onQRViewCreated,
            formatsAllowed: const [BarcodeFormat.qrcode],
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).colorScheme.primary,
              borderWidth: 8,
              borderRadius: 12,
              borderLength: 32,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
            ),
            onPermissionSet: (ctrl, granted) {
              if (!granted) {
                _showPermissionDenied(context);
              }
            },
          ),
          if (!_controllerReady)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    setState(() => _controllerReady = true);

    controller.scannedDataStream.listen((barcode) {
      if (_qrDetected) return;
      final String? code = barcode.code;
      if (code == null || code.isEmpty) return;

      _qrDetected = true;
      if (!mounted) return;
      Navigator.pop(context, code);
    });
  }

  void _showPermissionDenied(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text(
          'Permission to use the camera was denied. Please enable camera permissions in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}