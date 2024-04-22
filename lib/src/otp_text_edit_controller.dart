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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_autofill/src/base/strategy.dart';
import 'package:otp_autofill/src/otp_interactor.dart';
import 'package:otp_autofill/src/util/platform_wrapper.dart';

final _defaultOTPInteractor = OTPInteractor();

/// Custom [TextEditingController] for text views, IOS autofill is built in flutter.
///
/// This controller is responsible for managing the OTP code input, including
/// handling the code length, receiving the code, handling timeout exceptions,
/// and providing an error handler. It also has the option to automatically stop
/// listening for input after receiving the complete code.
class OTPTextEditController extends TextEditingController {
  /// The length of the OTP code.
  ///
  /// When the user enters an OTP code with the specified length,
  /// the [onCodeReceive] callback will be triggered.
  final int codeLength;

  /// The callback is triggered when the OTP code is received by the [OTPTextEditController].
  ///
  /// This callback can be used to perform actions when the code is received,
  /// such as validating the code or submitting a form.
  final StringCallback? onCodeReceive;

  /// A callback function that is called when a time-out exception occurs.
  ///
  /// If no SMS is received within 5 minutes, a TimeoutError will be triggered.
  final VoidCallback? onTimeOutException;

  /// This callback function is used to handle any exceptions that occur during the OTP text editing process.
  /// It takes an [Exception] as a parameter and can be used to perform custom error handling logic.
  final Function(Exception error)? errorHandler;

  /// Determines whether the controller should automatically stop listening
  /// for OTP input after receiving or error an OTP code.
  final bool autoStop;

  /// Interaction with OTP.
  @visibleForTesting
  final OTPInteractor otpInteractor;

  /// Wrapper for Platform io.
  @visibleForTesting
  final PlatformWrapper platform;

  OTPTextEditController({
    required this.codeLength,
    this.onCodeReceive,
    this.onTimeOutException,
    this.errorHandler,
    this.autoStop = true,
    OTPInteractor? otpInteractor,
    PlatformWrapper? platform,
  })  : otpInteractor = otpInteractor ?? _defaultOTPInteractor,
        platform = platform ?? PlatformWrapper() {
    addListener(checkForComplete);
  }

  /// Starts listening for the OTP code with the User Consent API.
  /// By default, it listens for SMS messages.
  /// Additional input strategies can be added using [OTPStrategy].
  ///
  /// Parameters:
  /// - [codeExtractor] a callback function that extracts the OTP code from the received message.
  /// - [strategies] additional OTP strategies to listen for.
  /// - [senderNumber] the sender number to filter the OTP messages.
  Future<void> startListenUserConsent(
    ExtractStringCallback codeExtractor, {
    List<OTPStrategy>? strategies,
    String? senderNumber,
  }) {
    final smsListen = otpInteractor.startListenUserConsent(senderNumber);
    final strategiesListen = strategies?.map((e) => e.listenForCode());

    final list = [
      if (platform.isAndroid) smsListen,
      if (strategiesListen != null) ...strategiesListen,
    ];

    if (list.isEmpty) return Future.value();

    return Stream.fromFutures(list).first.then(
      (value) {
        if (autoStop) {
          stopListen();
        }
        text = codeExtractor(value);
      },
    ).catchError(
      // ignore: avoid_types_on_closure_parameters
      (Object error) {
        if (autoStop) {
          stopListen();
        }
        if (error is PlatformException && error.code == '408') {
          onTimeOutException?.call();
        } else if (error is Exception) {
          errorHandler?.call(error);
        } else {
          throw Exception('Unexpected error: $error');
        }
      },
    );
  }

  /// Starts listening for OTP code using the Retriever API.
  ///
  /// Parameters:
  /// - [codeExtractor] callback function that extracts the OTP code from the received message.
  /// - [additionalStrategies] additional OTP strategies to listen for.
  Future<void> startListenRetriever(
    ExtractStringCallback codeExtractor, {
    List<OTPStrategy>? additionalStrategies,
  }) {
    final smsListen = otpInteractor.startListenRetriever();
    final strategiesListen = additionalStrategies?.map(
      (e) => e.listenForCode(),
    );

    final list = [
      if (platform.isAndroid) smsListen,
      if (strategiesListen != null) ...strategiesListen,
    ];

    if (list.isEmpty) return Future.value();

    return Stream.fromFutures(list).first.then(
      (value) {
        if (autoStop) {
          stopListen();
        }
        text = codeExtractor(value);
      },
    ).catchError(
      // ignore: avoid_types_on_closure_parameters
      (Object error) {
        if (autoStop) {
          stopListen();
        }
        if (error is PlatformException && error.code == '408') {
          onTimeOutException?.call();
        } else if (error is Exception) {
          errorHandler?.call(error);
        } else {
          throw Exception('Unexpected error: $error');
        }
      },
    );
  }

  /// Starts listening for the OTP code using the specified strategies and extracts the code when it is received.
  /// The extracted code is then set as the text of the controller.
  ///
  /// Parameters:
  /// - [strategies] additional OTP strategies to listen for code.
  /// - [codeExtractor] callback function that extracts the OTP code from the received message.
  void startListenOnlyStrategies(
    List<OTPStrategy>? strategies,
    ExtractStringCallback codeExtractor,
  ) {
    final strategiesListen = strategies?.map((e) => e.listenForCode());

    final list = [
      if (strategiesListen != null) ...strategiesListen,
    ];

    if (list.isEmpty) return;

    Stream.fromFutures(list).first.then((value) {
      text = codeExtractor(value);
    });
  }

  /// Broadcast receiver stops listening for OTP code.
  ///
  /// This method should be called in the `dispose` method of the widget
  /// or when you no longer need to listen for OTP codes.
  Future<Object?> stopListen() {
    return otpInteractor.stopListenForCode();
  }

  /// This method checks if the length of the entered text is equal to the code length.
  /// If it is, the [onCodeReceive] callback is called with the entered text as a parameter.
  void checkForComplete() {
    if (text.length == codeLength) onCodeReceive?.call(text);
  }
}
