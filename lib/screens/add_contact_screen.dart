import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/contact.dart';
import '../services/contact_service.dart';
import '../utils/constants.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _publicKeyController = TextEditingController();
  final _contactService = ContactService();
  final _scannerController = MobileScannerController();

  bool _isScanning = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _publicKeyController.dispose();
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_isSaving) {
      return;
    }

    String? rawValue;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null) {
      return;
    }

    final parsedContact = _parseQrContact(rawValue.trim());
    await _saveContact(parsedContact);
  }

  Future<void> _addManually() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    final contact = Contact(
      nickname: _nicknameController.text.trim(),
      publicKey: _publicKeyController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _saveContact(contact);
  }

  Contact _parseQrContact(String value) {
    final separatorIndex = value.indexOf(':');

    if (separatorIndex == -1) {
      return Contact(
        nickname: 'Unknown',
        publicKey: value,
        createdAt: DateTime.now(),
      );
    }

    final nickname = value.substring(0, separatorIndex).trim();
    final publicKey = value.substring(separatorIndex + 1).trim();

    return Contact(
      nickname: nickname.isEmpty ? 'Unknown' : nickname,
      publicKey: publicKey,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _saveContact(Contact contact) async {
    if (contact.publicKey.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await _contactService.init();
    await _contactService.addContact(contact);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Контакт добавлен'),
      ),
    );

    Navigator.pop(context);
  }

  String? _validateRequired(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Поле не должно быть пустым';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvixColors.background,
      appBar: AppBar(
        backgroundColor: AvixColors.background,
        foregroundColor: AvixColors.text,
        title: const Text('Добавить контакт'),
      ),
      body: SafeArea(
        child: _isScanning ? _buildScanner() : _buildManualForm(),
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              unawaited(_onQrDetected(capture));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _isScanning = false;
                      });
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AvixColors.text,
                side: const BorderSide(color: AvixColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Отмена'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _startScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvixColors.accent,
                  foregroundColor: AvixColors.text,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Сканировать QR'),
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nicknameController,
              validator: _validateRequired,
              autovalidateMode: AutovalidateMode.disabled,
              style: const TextStyle(color: AvixColors.text),
              cursorColor: AvixColors.accent,
              decoration: _inputDecoration('Никнейм'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _publicKeyController,
              validator: _validateRequired,
              autovalidateMode: AutovalidateMode.disabled,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(color: AvixColors.text),
              cursorColor: AvixColors.accent,
              decoration: _inputDecoration('Публичный ключ'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _addManually,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvixColors.accent,
                  foregroundColor: AvixColors.text,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Добавление...' : 'Добавить вручную',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF151515),
      errorStyle: const TextStyle(color: Colors.redAccent),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AvixColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
