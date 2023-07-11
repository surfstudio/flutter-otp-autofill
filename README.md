# OTP autofill

[![Build Status](https://shields.io/github/actions/workflow/status/surfstudio/flutter-otp-autofill/main.yml?logo=github&logoColor=white)](https://github.com/surfstudio/flutter-otp-autofill)
[![Coverage Status](https://img.shields.io/codecov/c/github/surfstudio/flutter-otp-autofill?logo=codecov&logoColor=white)](https://app.codecov.io/gh/surfstudio/flutter-otp-autofill)
[![Pub Version](https://img.shields.io/pub/v/otp_autofill?logo=dart&logoColor=white)](https://pub.dev/packages/otp_autofill)
[![Pub Likes](https://badgen.net/pub/likes/otp_autofill)](https://pub.dev/packages/otp_autofill)
[![Pub popularity](https://badgen.net/pub/popularity/otp_autofill)](https://pub.dev/packages/otp_autofill/score)
![Flutter Platform](https://badgen.net/pub/flutter-platform/otp_autofill)

This package is part of the [SurfGear](https://github.com/surfstudio/SurfGear) toolkit made by [Surf](https://surf.ru).

[![OTP autofill](https://i.ibb.co/dG8zd7c/OTP-autofill.png)](https://github.com/surfstudio/SurfGear)

## Description

This plugin uses [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview) and [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview) on Android.

You could use autofill from another input by using OTPStrategy. (e.g. from push-notification).

For testing you could create `TestStrategy`.

## iOS

On iOS OTP autofill is built in `TextField`.
Code from sms stores for 3 minutes.

### Rules for sms

1. Sms must contain the word `code` or it translation to ios supported localizations.
2. Must be only one digit sequence in sms.

### iOS Testing

iOS can receive number from any other number.

## Android

`OTPInteractor.hint` - show system dialog to select saved phone numbers (recommendation from google).
`OTPInteractor.getAppSignature` - create hash-code of your application, that used in [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview).
`OTPInteractor.startListenUserConsent` - BroadcastReceiver start listen for code from Google Services for 5 minutes. Above 5 minutes raise timeout exception. Using [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview).
`OTPInteractor.startListenRetriever` - BroadcastReceiver start listen for code from Google Services for 5 minutes. Above 5 minutes raise timeout exception. Using [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview).
`OTPInteractor.stopListenForCode` - use in dispose.

Plugin receive full sms text, need parser for sms.

If you use [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview) then system ask for permission to reed incoming message.

### Rules for sms. SMS User Consent API

1. The message contains a 4-10 character alphanumeric string with at least one number.
2. The message was sent by a phone number that's not in the user's contacts.
3. If you specified the sender's phone number, the message was sent by that number.

### Rules for sms. SMS Retriever API

1. Be no longer than 140 bytes.
2. Contain a one-time code that the client sends back to your server to complete the verification flow.
3. Include an 11-character hash string that identifies your app ([documentation for server](https://developers.google.com/identity/sms-retriever/verify#computing_your_apps_hash_string), for testing you can get in from `OTPInteractor.getAppSignature`).

### Android Testing

`OTPInteractor.startListenForCode` has `senderPhone` argument. Application start receiving code from this number.

## Usage

You could user `OTPInteractor` to interact with OTP.

For easy implementation you could use `OTPTextEditController` as a controller to your `TextField`.

`OTPTextEditController.startListenUserConsent` - use [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview), and custom strategies.
`OTPTextEditController.startListenRetriever` - use [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview), and custom strategies.
`OTPTextEditController.startListenOnlyStrategies` - listen only custom strategies.
`OTPTextEditController.stopListen` - use in dispose.

## Installation

Add `otp_autofill` to your `pubspec.yaml` file:

```yaml
dependencies:
  otp_autofill: $currentVersion$
```

<p>At this moment, the current version of <code>otp_autofill</code> is <a href="https://pub.dev/packages/otp_autofill"><img style="vertical-align:middle;" src="https://img.shields.io/pub/v/otp_autofill.svg" alt="otp_autofill version"></a>.</p>

### Android Installation

Set `minSdkVersion` at least to 19 in `<project root>/project/android/app/build.gradle`.

``` gradle
android {
  ...
  defaultConfig {
    ...
    minSdkVersion 19
    ...
  }
  ...
}
```

## Example

1. Create simple strategy

```dart
class SampleStrategy extends OTPStrategy {
  @override
  Future<String> listenForCode() {
    return Future.delayed(
      const Duration(seconds: 4),
      () => 'Your code is 54321',
    );
  }
}
```

2. Initialize listener and set

```dart
late OTPTextEditController controller;
final scaffoldKey = GlobalKey();

@override
void initState() {
  super.initState();
  _otpInteractor = OTPInteractor();
  _otpInteractor.getAppSignature()
      .then((value) => print('signature - $value'));
  controller = OTPTextEditController(
    codeLength: 5,
    onCodeReceive: (code) => print('Your Application receive code - $code'),
  )..startListenUserConsent(
      (code) {
        final exp = RegExp(r'(\d{5})');
        return exp.stringMatch(code ?? '') ?? '';
      },
      strategies: [
        SampleStrategy(),
      ],
    );
}
```

## Send new code

To get new code you can pass callback onTimeout Exception to detect and process this situation.

```dart
controller = OTPTextEditController(
      codeLength: 5,
      onCodeReceive: (code) => print('Your Application receive code - $code'),
      otpInteractor: _otpInteractor,
      onTimeOutException: () {
        //TODO: start new listen to get new code
        controller.startListenUserConsent(
          (code) {
            final exp = RegExp(r'(\d{5})');
            return exp.stringMatch(code ?? '') ?? '';
          },
          strategies: [
            SampleStrategy(),
          ],
        );
      },
    )..startListenUserConsent(
        (code) {
          final exp = RegExp(r'(\d{5})');
          return exp.stringMatch(code ?? '') ?? '';
        },
        strategies: [
          TimeoutStrategy(),
        ],
      );
```

## Changelog

All notable changes to this project will be documented in [this file](./CHANGELOG.md).

## Issues

To report your issues, submit them directly in the [Issues](https://github.com/surfstudio/flutter-otp-autofill/issues) section.

## Contribute

If you would like to contribute to the package (e.g. by improving the documentation, fixing a bug or adding a cool new feature), please read our [contribution guide](./CONTRIBUTING.md) first and send us your pull request.

Your PRs are always welcome.

## How to reach us

Please feel free to ask any questions about this package. Join our community chat on Telegram. We speak English and Russian.

[![Telegram](https://img.shields.io/badge/chat-on%20Telegram-blue.svg)](https://t.me/SurfGear)

## License

[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)
