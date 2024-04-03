# OTP autofill

[![Build Status](https://shields.io/github/actions/workflow/status/surfstudio/flutter-otp-autofill/main.yml?logo=github&logoColor=white)](https://github.com/surfstudio/flutter-otp-autofill)
[![Coverage Status](https://img.shields.io/codecov/c/github/surfstudio/flutter-otp-autofill?logo=codecov&logoColor=white)](https://app.codecov.io/gh/surfstudio/flutter-otp-autofill)
[![Pub Version](https://img.shields.io/pub/v/otp_autofill?logo=dart&logoColor=white)](https://pub.dev/packages/otp_autofill)
[![Pub Likes](https://badgen.net/pub/likes/otp_autofill)](https://pub.dev/packages/otp_autofill)
[![Pub popularity](https://badgen.net/pub/popularity/otp_autofill)](https://pub.dev/packages/otp_autofill/score)
![Flutter Platform](https://badgen.net/pub/flutter-platform/otp_autofill)

This package is a part of the [SurfGear](https://github.com/surfstudio/SurfGear) toolkit made by [Surf](https://surf.ru).

[![OTP autofill](https://i.ibb.co/dG8zd7c/OTP-autofill.png)](https://github.com/surfstudio/SurfGear)

## Description

This plugin uses the [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview) and [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview) on Android.

You could use autofill from another input by using the OTPStrategy (e.g. from push-notification).

For testing you could create a `TestStrategy`.

## iOS

On iOS, the OTP autofill feature is integrated into the `TextField` component. 
The code received from an SMS is stored for a duration of 3 minutes.

### Rules for sms

1. Sms must contain the word `code` or its translation in iOS supported localizations.
2. The sms should contain only one sequence of digits.

### iOS Testing

The iOS platform is capable of receiving OTP from any phone number, not just a specific sender.

## Android

`OTPInteractor.hint` - displays a system dialog that allows the user to select from their saved phone numbers (recommendation from Google).  
`OTPInteractor.getAppSignature` - creates the hash code of your application, which is used in the [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview).  
`OTPInteractor.startListenUserConsent` - the broadcast receiver that starts listening for OTP codes using the [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview). It listens for a duration of 5 minutes, after which a timeout exception occurs.  
`OTPInteractor.startListenRetriever` - the broadcast receiver that starts listening for OTP codes using the [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview). It listens for a duration of 5 minutes, after which a timeout exception occurs.  
`OTPInteractor.stopListenForCode` - used in dispose.

The plugin is designed to receive the full text of an SMS message and requires a parser to extract the relevant information from the message.

If you use the [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview), the system will prompt the user for permission to access and read incoming messages.

### Rules for SMS when using [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview)

1. The message should contain an alphanumeric string of 4 to 10 characters, with at least one digit.
2. The message was sent from a phone number that is not in the user's contacts.
3. If the sender's phone number is specified, the message must originate from that number.

### Rules for SMS when using [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview)

1. The length should not exceed 140 bytes.
2. It should contain a one-time code that the client sends back to your server to complete the verification process.
3. It should include an 11-character hash string that identifies your app (refer to the [documentation for server](https://developers.google.com/identity/sms-retriever/verify#computing_your_apps_hash_string) for more details). For testing, you can obtain it from `OTPInteractor.getAppSignature`.

### Android Testing

The `OTPInteractor.startListenForCode` method allows the application to start receiving verification codes from a specific phone number, specified by the `senderPhone` argument.

## Usage

You should use `OTPInteractor` to interact with OTP.

To simplify implementation, consider using the `OTPTextEditController` as a controller for your `TextField`.

`OTPTextEditController.startListenUserConsent` - uses the [SMS User Consent API](https://developers.google.com/identity/sms-retriever/user-consent/overview) and listens to user strategies.
`OTPTextEditController.startListenRetriever` - uses the [SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview) and listens to user strategies.
`OTPTextEditController.startListenOnlyStrategies` - only listens to user strategies.
`OTPTextEditController.stopListen` - used in dispose.

## Installation

Add `otp_autofill` to your `pubspec.yaml` file:

```yaml
dependencies:
  otp_autofill: $currentVersion$
```

<p>At this moment, the current version of <code>otp_autofill</code> is <a href="https://pub.dev/packages/otp_autofill"><img style="vertical-align:middle;" src="https://img.shields.io/pub/v/otp_autofill.svg" alt="otp_autofill version"></a>.</p>

### Android Installation

Set `minSdkVersion` at least to 19 in `<project root>/android/app/build.gradle`.

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

1. Create a simple strategy

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

2. Initialize and set the listener

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

To receive a new code when a timeout exception occurs, you can pass a callback function to the `onTimeOutException` parameter and start listen for a new code.

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

All significant changes to this project will be documented in [this file](./CHANGELOG.md).

## Issues

To report any issues, submit them directly in the [Issues](https://github.com/surfstudio/flutter-otp-autofill/issues) section.

## Contribute

If you wish to contribute to the package (for instance, by enhancing the documentation, fixing a bug, or introducing a new feature), please review our [contribution guide](./CONTRIBUTING.md) first and then submit your pull request.

Your PRs are always welcome.

## How to reach us

Please don't hesitate to ask any questions about this package. Join our community chat on Telegram. We communicate in both English and Russian.

[![Telegram](https://img.shields.io/badge/chat-on%20Telegram-blue.svg)](https://t.me/SurfGear)

## License

[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)
