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

import 'package:flutter/services.dart';
import 'package:otp_autofill/src/base/exceptions.dart';
import 'package:otp_autofill/src/util/platform_wrapper.dart';

typedef StringCallback = void Function(String);

/// Channel.
const channelName = 'otp_surfstudio';

/// Methods.
const getTelephoneHint = 'getTelephoneHint';
const startListenUserConsentMethod = 'startListenUserConsent';
const startListenRetrieverMethod = 'startListenRetriever';
const stopListenForCodeMethod = 'stopListenForCode';
const getAppSignatureMethod = 'getAppSignature';

/// Arguments.
const senderTelephoneNumber = 'senderTelephoneNumber';
const _defaultChannel = MethodChannel(channelName);

/// This class provides methods to interact with the native platform in order
/// to retrieve the OTP code and telephone hint.
class OTPInteractor {
  final MethodChannel _channel;
  final PlatformWrapper _platform;

  /// Display a telephone picker and retrieve the chosen telephone number.
  Future<String?> get hint {
    if (_platform.isAndroid) {
      return _channel.invokeMethod<String>(getTelephoneHint);
    } else {
      throw UnsupportedPlatform();
    }
  }

  OTPInteractor({
    MethodChannel channel = _defaultChannel,
    PlatformWrapper? platform,
  })  : assert(channel.name == channelName),
        _channel = channel,
        _platform = platform ?? PlatformWrapper();

  /// Get the app signature that is used in the Retriever API.
  Future<String?> getAppSignature() async {
    if (_platform.isAndroid) {
      return _channel.invokeMethod<String>(getAppSignatureMethod);
    } else {
      throw UnsupportedPlatform();
    }
  }

  /// Stops listening for OTP codes.
  ///
  /// This method should be called in the `dispose` method of the widget
  /// or when you no longer need to listen for OTP codes.
  Future<Object?> stopListenForCode() {
    return _channel.invokeMethod<Object>(stopListenForCodeMethod);
  }

  /// The broadcast receiver starts listening for OTP codes using the User Consent API.
  Future<String?> startListenUserConsent([String? senderPhone]) async {
    if (_platform.isAndroid) {
      return _channel.invokeMethod<String>(
        startListenUserConsentMethod,
        <String, String?>{
          senderTelephoneNumber: senderPhone,
        },
      );
    } else {
      throw UnsupportedPlatform();
    }
  }

  /// The broadcast receiver starts listening for OTP codes using the Retriever API.
  Future<String?> startListenRetriever() async {
    if (_platform.isAndroid) {
      return _channel.invokeMethod<String>(startListenRetrieverMethod);
    } else {
      throw UnsupportedPlatform();
    }
  }
}
