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

/// Экран ввода кода
class AuthConfirmationScreen extends StatefulWidget {
  const AuthConfirmationScreen({Key? key}) : super(key: key);

  @override
  _AuthConfirmationScreenState createState() => _AuthConfirmationScreenState();
}

class _AuthConfirmationScreenState extends State<AuthConfirmationScreen> {
  /// Количество символов в коде
  static const int _codeLength = 6;

  late OTPTextEditController _codeController;
  late OTPInteractor _otpInteractor;

  @override
  void initState() {
    super.initState();
    _otpInteractor = OTPInteractor();

    _codeController = OTPTextEditController(
      codeLength: _codeLength,
      onCodeReceive: (code) => debugPrint('Your Application receive code - $code'),
      otpInteractor: _otpInteractor,
    )..startListenUserConsent(_setCode);
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
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  controller: _codeController,
                  maxLength: _codeLength,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
    super.dispose();
    await _codeController.stopListen();
  }

  /// Подставить код в поле
  String _setCode(String? code) {
    final exp = RegExp(r'\d' '{$_codeLength}');

    return exp.stringMatch(code ?? '') ?? '';
  }
}