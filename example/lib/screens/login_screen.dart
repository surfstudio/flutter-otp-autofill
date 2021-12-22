// Copyright (c) 2019-present,  SurfStudio LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_autofill/otp_autofill.dart';
import 'package:otp_autofill_example/screens/auth_confirmation_screen.dart';

/// Экран входа
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Количество символов в номере телефона
  static const int _phoneLength = 11;

  late TextEditingController _phoneController;
  late OTPInteractor _otpInteractor;

  @override
  void initState() {
    super.initState();
    _otpInteractor = OTPInteractor();
    _phoneController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        label: Text('Номер телефона'),
                        prefix: Text('+'),
                      ),
                      maxLength: _phoneLength,
                      onSubmitted: _validatePhone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        onPressed: _askPhoneHint,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Colors.blue,
                          size: 28,
                        ),
                        splashRadius: 30,
                        splashColor: Colors.blue.shade50,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _validatePhone(_phoneController.text),
                  child: const Text('Войти'),
                ),
              ],
            ),
          ),
        ),
        resizeToAvoidBottomInset: false,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _phoneController.dispose();
    super.dispose();
  }

  /// Открыть окно выбора номера телефона
  Future<void> _askPhoneHint() async {
    try {
      var hint = await _otpInteractor.hint;

      if (hint != null) {
        final exp = RegExp(r'\d' '{$_phoneLength}');
        hint = exp.stringMatch(hint);
      }

      _phoneController.text = hint ?? '';
      debugPrint('--------_phoneController.text ${_phoneController.text}');
    } on Exception catch (e) {
      _errorHandler(e);
    }
  }

  /// Обработка ошибки
  void _errorHandler(Exception exception) {
    ScaffoldMessenger.of(context).showSnackBar(
      _exceptionSnackBar(
        exception.toString(),
      ),
    );

    debugPrint('--------Flutter _errorHandler ${exception.toString()}');
  }

  /// Снек-бар
  SnackBar _exceptionSnackBar(String message) {
    return SnackBar(
      backgroundColor: Colors.pink,
      content: Text(message),
    );
  }

  /// Валидация поля
  void _validatePhone(String? value) {
    FocusScope.of(context).unfocus();

    if (value != null && value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _exceptionSnackBar('Обязательное поле'),
      );

      return;
    }

    if (value != null && value.length < _phoneLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        _exceptionSnackBar('Некорректный номер телефона'),
      );

      return;
    }

    /// Получаем подпись приложения
    _otpInteractor.getAppSignature().then((value) => debugPrint('signature - $value'));

    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthConfirmationScreen(),
      ),
    );
  }
}