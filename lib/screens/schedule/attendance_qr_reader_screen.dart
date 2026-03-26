import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AttendanceQrReaderScreen extends StatefulWidget {
  const AttendanceQrReaderScreen({super.key});

  @override
  State<AttendanceQrReaderScreen> createState() => _AttendanceQrReaderScreenState();
}

class _AttendanceQrReaderScreenState extends State<AttendanceQrReaderScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRコードを読み取り')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.trim().isEmpty) return;
              _handled = true;
              Navigator.of(context).pop(raw.trim());
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black.withOpacity(0.45),
              child: const Text(
                '教室のQRコードを読み取ってください\n読み取り後に出席サイトを開きます',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
