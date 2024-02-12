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
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otp_autofill/otp_autofill.dart';
import 'package:otp_autofill/src/util/platform_wrapper.dart';

void main() {
  late OTPInteractor otpInteractor;
  late MockMethodChannel methodChannel;
  late MockPlatformWrapper platformWrapper;

  setUp(
    () {
      platformWrapper = MockPlatformWrapper();
      methodChannel = MockMethodChannel();
      when(() => methodChannel.name).thenReturn('otp_surfstudio');

      otpInteractor = OTPInteractor(
        channel: methodChannel,
        platform: platformWrapper,
      );
      when(() => platformWrapper.isAndroid).thenReturn(true);
    },
  );

  test(
    'The methodChannel must have the correct name',
    () {
      final methodChannel = MockMethodChannel();
      when(() => methodChannel.name).thenReturn('otp_surfstudio');

      expect(() => OTPInteractor(channel: methodChannel), returnsNormally);
    },
  );

  test(
    'If methodChannel name is not correct, assertion error should be thrown',
    () {
      final methodChannel = MockMethodChannel();
      when(() => methodChannel.name).thenReturn('test_channel');

      expect(() => OTPInteractor(channel: methodChannel), throwsAssertionError);
    },
  );

  test(
    'Call stopListenForCode method on the OTPInteractor should call invokeMethod with correct params',
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
    'Call hint on the OTPInteractor should call invokeMethod with correct params',
    () async {
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

  test(
    'Call getAppSignature method on the OTPInteractor should call invokeMethod with correct params',
    () async {
      when(
        () => methodChannel.invokeMethod<String>(
          any(),
        ),
      ).thenAnswer(
        (invocation) => Future.value(),
      );

      await otpInteractor.getAppSignature();

      verify(
        () => methodChannel.invokeMethod<String>('getAppSignature'),
      ).called(1);
    },
  );

  test(
    'Call stopListenForCode method on the OTPInteractor should call invokeMethod with correct params',
    () async {
      when(
        () => methodChannel.invokeMethod<Object>(
          any(),
        ),
      ).thenAnswer(
        (invocation) => Future.value(),
      );

      await otpInteractor.stopListenForCode();

      verify(() => methodChannel.invokeMethod<Object>('stopListenForCode')).called(1);
    },
  );

  group('Call startListenUserConsent method on OTPInteractor', () {
    test(
      'with phone number should call invokeMethod with correct params',
      () async {
        const phoneNumber = '89000000000';
        when(
          () => methodChannel.invokeMethod<String>(
            any(),
            {
              'senderTelephoneNumber': phoneNumber,
            },
          ),
        ).thenAnswer(
          (invocation) => Future.value(),
        );

        await otpInteractor.startListenUserConsent(phoneNumber);

        verify(
          () => methodChannel.invokeMethod<String>(
            'startListenUserConsent',
            {
              'senderTelephoneNumber': phoneNumber,
            },
          ),
        ).called(1);
      },
    );

    test(
      'without phone number should call invokeMethod with correct params',
      () async {
        when(
          () => methodChannel.invokeMethod<String>(
            any(),
            {
              'senderTelephoneNumber': null,
            },
          ),
        ).thenAnswer(
          (invocation) => Future.value(),
        );

        await otpInteractor.startListenUserConsent();

        verify(
          () => methodChannel.invokeMethod<String>(
            'startListenUserConsent',
            {
              'senderTelephoneNumber': null,
            },
          ),
        ).called(1);
      },
    );
  });

  test(
    'Call startListenRetriever method on OTPInteractor should call invokeMethod with correct params',
    () async {
      when(
        () => methodChannel.invokeMethod<String>(
          any(),
        ),
      ).thenAnswer(
        (invocation) => Future.value(),
      );

      await otpInteractor.startListenRetriever();

      verify(
        () => methodChannel.invokeMethod<String>('startListenRetriever'),
      ).called(1);
    },
  );

  group(
    'If call any method on the OTPInteractor not on android there should be an UnsupportedPlatform error:',
    () {
      test(
        'startListenRetriever',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);

          when(
            () => methodChannel.invokeMethod<String>(
              any(),
            ),
          ).thenAnswer(
            (invocation) => Future.value(),
          );

          expect(
            otpInteractor.startListenRetriever,
            throwsA(isA<UnsupportedPlatform>()),
          );
        },
      );

      test(
        'hint',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);

          when(
            () => methodChannel.invokeMethod<String>(
              any(),
            ),
          ).thenAnswer(
            (invocation) => Future.value(),
          );

          expect(
            () => otpInteractor.hint,
            throwsA(isA<UnsupportedPlatform>()),
          );
        },
      );

      test(
        'getAppSignature',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);

          when(
            () => methodChannel.invokeMethod<String>(
              any(),
            ),
          ).thenAnswer(
            (invocation) => Future.value(),
          );

          expect(
            otpInteractor.getAppSignature(),
            throwsA(isA<UnsupportedPlatform>()),
          );
        },
      );

      test(
        'startListenUserConsent',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);

          when(
            () => methodChannel.invokeMethod<String>(
              any(),
            ),
          ).thenAnswer(
            (invocation) => Future.value(),
          );

          expect(
            otpInteractor.startListenUserConsent(),
            throwsA(isA<UnsupportedPlatform>()),
          );
        },
      );
    },
  );
}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockPlatformWrapper extends Mock implements PlatformWrapper {}
