import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/supabase_service.dart';
import '../models/check_in_result.dart';

class CodeScanner extends StatefulWidget {
  const CodeScanner({Key? key}) : super(key: key);

  @override
  State<CodeScanner> createState() => _CodeScannerState();
}

class _CodeScannerState extends State<CodeScanner> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      extendBody: true,
      body: QR(), // The scanner view
    );
  }
}

class QR extends StatefulWidget {
  const QR({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRState();
}

class _QRState extends State<QR> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  final _svc = SupabaseService();
  bool _handledScan = false; // prevent double handling

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildQrView(context);

  Widget _buildQrView(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = (size.width < 400 || size.height < 400) ? 250.0 : 300.0;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFFF2AC02),
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);

    controller.scannedDataStream.listen((scanData) async {
      if (_handledScan) return; // only handle first scan
      _handledScan = true;

      await controller.pauseCamera();
      result = scanData;
      final raw = result?.code ?? '';
      log('Scanned Data: $raw');

      try {
        // 1) Try to extract UUID from the QR data itself
        String? eventId = _extractEventId(raw);

        // 2) If not a UUID, treat as URL and look up Events.id by qr_code_url
        if (eventId == null) {
          eventId = await _svc.getEventIdByQrUrl(raw);
          if (eventId == null) {
            eventId = await _svc.getEventIdByQrUrlLoose(raw);
          }
        }

        if (eventId == null) {
          throw Exception('Invalid QR: no event found for this QR link.');
        }

        // Get Firebase UID -> matches users.firebase_uid
        final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
        if (firebaseUid == null) {
          throw Exception('You must be logged in to check in.');
        }

        // Call the atomic RPC
        final res = await _svc.checkInToEvent(
          firebaseUid: firebaseUid,
          eventId: eventId,
        );

        await _showCheckedInDialog(context, res);

        if (!mounted) return;
        // Return to main dashboard (adjust for your routes)
        Navigator.of(context).pop();
        // Or: Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
      } catch (e, st) {
        log('Check-in error: $e\n$st');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
        // Allow retry after error
        _handledScan = false;
        await controller.resumeCamera();
      }
    });
  }

  /// Accepts:
  ///  - raw UUID "8a71a2c6-2a3f-4b39-8d0f-8a6f0b3c2f18"
  ///  - JSON {"event_id":"<uuid>"}
  ///  - URL-like ".../event/<uuid>" or "...?event_id=<uuid>"
  String? _extractEventId(String raw) {
    final uuidRe = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-f]{12}',
      caseSensitive: false,
    );

    // 1) Direct UUID in string
    final direct = uuidRe.firstMatch(raw)?.group(0);
    if (direct != null) return direct;

    // 2) Try JSON with event_id
    try {
      final obj = json.decode(raw);
      if (obj is Map && obj['event_id'] is String) {
        final m = uuidRe.firstMatch(obj['event_id'] as String)?.group(0);
        if (m != null) return m;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _showCheckedInDialog(BuildContext context, CheckInResult res) {
    final title = res.alreadyCheckedIn ? 'Already Checked In' : 'Checked In!';
    final msg = res.alreadyCheckedIn
        ? 'You already received points for this event.'
        : 'You earned ${res.eventPoints} points.\n'
          'Total: ${res.newPoints} • Events: ${res.newEventsAttended}\n'
          'Leaderboard Rank: #${res.newRank}';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                res.alreadyCheckedIn ? Icons.info : Icons.check_circle,
                size: 56,
                color: const Color(0xFFF2AC02),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No Camera Permission')));
    }
  }
}
