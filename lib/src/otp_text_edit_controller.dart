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
import 'package:otp_autofill/src/utill/platform_wrapper.dart';

final _defaultOTPInteractor = OTPInteractor();

/// Custom controller for text views, IOS autofill is built in flutter.
class OTPTextEditController extends TextEditingController {
  /// OTP code length - trigger for callback.
  final int codeLength;

  /// [OTPTextEditController]'s receive OTP code callback.
  final StringCallback? onCodeReceive;

  /// Receiver gets TimeoutError after 5 minutes without sms.
  final VoidCallback? onTimeOutException;

  /// Error handler.
  final Function(Exception error)? errorHandler;

  /// Stop listening after receiving or error an OTP code.
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

  /// Start listen for OTP code with User Consent API
  /// sms by default
  /// could be added another input as [OTPStrategy].
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

  /// Start listen for OTP code with Retriever API
  /// sms by default
  /// could be added another input as [OTPStrategy].
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

  /// Get OTP code from another input
  /// don't register any BroadcastReceivers.
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

  /// Broadcast receiver stop listen for OTP code, use in dispose.
  Future<Object?> stopListen() {
    return otpInteractor.stopListenForCode();
  }

  /// Call onComplete callback if code entered.
  void checkForComplete() {
    if (text.length == codeLength) onCodeReceive?.call(text);
  }
}
