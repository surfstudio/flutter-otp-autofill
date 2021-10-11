import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otp_autofill/otp_autofill.dart';
import 'package:otp_autofill/src/utill/platform_wrapper.dart';

void main() {
  late OTPInteractor otpInteractor;
  late FakeMethodChannel methodChannel;
  late FakePlatformWrapper platformWrapper;

  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  setUp(
    () {
      platformWrapper = FakePlatformWrapper();
      methodChannel = FakeMethodChannel();
      when(() => methodChannel.name).thenReturn('otp_surfstudio');

      otpInteractor = OTPInteractor(
        channel: methodChannel,
        platform: platformWrapper,
      );
    },
  );

  test(
    'The methodChannel must have the correct name',
    () {
      final methodChannel = FakeMethodChannel();
      when(() => methodChannel.name).thenReturn('otp_surfstudio');

      expect(() => OTPInteractor(channel: methodChannel), returnsNormally);
    },
  );

  test(
    'If the methodChannel name is not correct, there should be an error',
    () {
      final methodChannel = FakeMethodChannel();
      when(() => methodChannel.name).thenReturn('test_channel');

      expect(() => OTPInteractor(channel: methodChannel), throwsAssertionError);
    },
  );

  test(
    'Method stopListenForCode must be called with the correct parameter',
    () async {
      when(
        () => methodChannel.invokeMethod<Object>(
          any(),
        ),
      ).thenAnswer(
        (invocation) => Future.value(),
      );

      await otpInteractor.stopListenForCode();

      verify(
        () => methodChannel.invokeMethod<Object>('stopListenForCode'),
      ).called(1);
    },
  );

  test(
    'Call hint on OTPInteractor should call correct method chanel invokeMethod',
    () async {
      when(() => platformWrapper.isAndroid).thenReturn(true);

      when(
        () => methodChannel.invokeMethod<String>(
          any(),
        ),
      ).thenAnswer(
        (invocation) => Future.value(),
      );

      await otpInteractor.hint;

      verify(
        () => methodChannel.invokeMethod<String>('getTelephoneHint'),
      ).called(1);
    },
  );
}

class FakeMethodChannel extends Mock implements MethodChannel {}

class FakePlatformWrapper extends Mock implements PlatformWrapper {}
