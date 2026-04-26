import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/database_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final DatabaseService _dbService = DatabaseService();
  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Class QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _handleCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay UI
          Column(
            children: [
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(40),
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Point camera at the QR code shown by your teacher',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCode(String code) async {
    setState(() => _isScanned = true);

    final appState = context.read<AppState>();
    
    if (appState.currentUser == null) {
      _showSnackBar('Ошибка: Вы не авторизованы', Colors.red);
      setState(() => _isScanned = false);
      return;
    }

    final error = await appState.joinClass(code);

    if (error == null) {
      _showSnackBar('Успешно присоединились к классу! 🎉', Colors.green);
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _isScanned = false);
      _showSnackBar(error, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
