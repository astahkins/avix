import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class NicknameScreen extends StatefulWidget {
  final String email;
  final String code;

  const NicknameScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _onFinishRegistrationPressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final nickname = _nicknameController.text.trim();

    await _authService.register(
      widget.email,
      widget.code,
      nickname,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const _HomePlaceholderScreen(),
      ),
    );
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    final nicknameRegExp = RegExp(r'^[A-Za-zА-Яа-яЁё0-9_]+$');

    if (nickname.length < 3) {
      return 'Ник должен быть не короче 3 символов';
    }

    if (!nicknameRegExp.hasMatch(nickname)) {
      return 'Используйте только буквы, цифры и _';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvixColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nicknameController,
                  validator: _validateNickname,
                  autovalidateMode: AutovalidateMode.disabled,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: AvixColors.text),
                  cursorColor: AvixColors.accent,
                  decoration: InputDecoration(
                    labelText: 'Ник',
                    labelStyle: const TextStyle(color: Colors.white70),
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
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  onPressed: _onFinishRegistrationPressed,
                  text: _isLoading ? 'Регистрация...' : 'Завершить регистрацию',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePlaceholderScreen extends StatelessWidget {
  const _HomePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AvixColors.background,
      body: Center(
        child: Text(
          'Главный экран (заглушка)',
          style: TextStyle(
            color: AvixColors.text,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
