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
import 'package:surf_lint_rules/surf_lint_rules.dart';

const testCode = '54321';
const codeFromTestStrategyFirst = '23451';
const codeFromTestStrategySecond = '23452';
const codeFromTestStrategyThird = '23453';
const codeFromOTPInteractor = '67890';

Future<void> _futureDelayed() {
  return Future<void>.delayed(
    const Duration(milliseconds: 300),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Exception());
  });

  late OTPTextEditController controller;
  late MockOTPInteractor otpInteractor;
  late MockPlatformWrapper platformWrapper;
  late MockOnTimeoutException onTimeOutException;
  late MockOnException onException;

  var codeOnCodeReceive = '';

  setUp(() {
    otpInteractor = MockOTPInteractor();
    platformWrapper = MockPlatformWrapper();
    when(() => platformWrapper.isAndroid).thenReturn(true);

    onTimeOutException = MockOnTimeoutException();
    when(() => onTimeOutException.call())
        .thenAnswer((invocation) => Future<void>.value());

    onException = MockOnException();
    when(() => onException.call(any()))
        .thenAnswer((invocation) => Future<void>.value());

    controller = OTPTextEditController(
      otpInteractor: otpInteractor,
      codeLength: testCode.length,
      onCodeReceive: (code) {
        codeOnCodeReceive = code;
      },
      platform: platformWrapper,
      onTimeOutException: onTimeOutException,
      errorHandler: onException,
    );
  });

  test(
    'If you do not pass the otpInteractor when creating a OTPTextEditController, '
    'it will have a default value',
    () {
      controller = OTPTextEditController(
        codeLength: testCode.length,
        platform: platformWrapper,
      );

      expect(controller.otpInteractor, isNotNull);
    },
  );

  test(
    'If you do not pass the platform when creating a OTPTextEditController, '
    'it will have a default value',
    () {
      controller = OTPTextEditController(
        codeLength: testCode.length,
        otpInteractor: otpInteractor,
      );

      expect(controller.platform, isNotNull);
    },
  );

  test(
    'When code filled up onCodeReceive must be called',
    () async {
      controller.startListenOnlyStrategies(
        [TestStrategy(code: testCode)],
        (code) {
          final exp = RegExp(r'(\d{5})');
          return exp.stringMatch(code ?? '') ?? '';
        },
      );

      expect(codeOnCodeReceive, isEmpty);

      await _futureDelayed();

      expect(codeOnCodeReceive, testCode);
    },
  );

  group(
    'Call method startListenOnlyStrategies',
    () {
      test(
        'Controller.text should be equal code from strategy',
        () async {
          controller.startListenOnlyStrategies(
            [TestStrategy(code: codeFromTestStrategyFirst)],
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          expect(controller.text, equals(codeFromTestStrategyFirst));
        },
      );

      test(
        'Controller.text should be equal code from fastest strategy',
        () async {
          controller.startListenOnlyStrategies(
            [
              TestStrategy(code: codeFromTestStrategyFirst, duration: 15),
              TestStrategy(code: codeFromTestStrategySecond, duration: 10),
              TestStrategy(code: codeFromTestStrategyThird, duration: 5),
            ],
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          expect(controller.text, equals(codeFromTestStrategyThird));
        },
      );
    },
  );

  group(
    'Call method startListenUserConsent on OTPTextEditController:',
    () {
      const senderNumber = 'test number';

      test(
        'The method startListenUserConsent on otpInteractor must be called',
        () async {
          when(() => otpInteractor.startListenUserConsent(senderNumber))
              .thenAnswer((invocation) =>
                  Future.value('Your code is $codeFromOTPInteractor'));

          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          await controller.startListenUserConsent(
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
            strategies: [TestStrategy(code: testCode)],
            senderNumber: senderNumber,
          );

          verify(() => otpInteractor.startListenUserConsent(senderNumber))
              .called(1);
        },
      );

      test(
        'If otpInteractor faster then other sends a code, the controller.text must be equal to this code',
        () async {
          when(() => otpInteractor.startListenUserConsent(senderNumber))
              .thenAnswer((invocation) =>
                  Future.value('Your code is $codeFromOTPInteractor'));

          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          unawaited(
            controller.startListenUserConsent(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              strategies: [TestStrategy(code: testCode)],
              senderNumber: senderNumber,
            ),
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          verify(() => otpInteractor.startListenUserConsent(senderNumber))
              .called(1);

          expect(controller.text, equals(codeFromOTPInteractor));
        },
      );

      test(
        'If strategy faster then startListenUserConsent, should use code from strategy',
        () async {
          when(() => otpInteractor.startListenUserConsent(senderNumber))
              .thenAnswer(
            (invocation) => Future.delayed(
              const Duration(milliseconds: 20),
              () => codeFromOTPInteractor,
            ),
          );

          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          unawaited(
            controller.startListenUserConsent(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              strategies: [
                TestStrategy(
                  code: codeFromTestStrategyFirst,
                  duration: 10,
                ),
              ],
              senderNumber: senderNumber,
            ),
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          expect(controller.text, equals(codeFromTestStrategyFirst));
        },
      );

      test(
        'Should use code from fastest source',
        () async {
          when(() => otpInteractor.startListenUserConsent(senderNumber))
              .thenAnswer(
            (invocation) => Future.delayed(
              const Duration(milliseconds: 20),
              () => codeFromOTPInteractor,
            ),
          );

          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          unawaited(
            controller.startListenUserConsent(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              strategies: [
                TestStrategy(
                  code: codeFromTestStrategyFirst,
                  duration: 15,
                ),
                TestStrategy(
                  code: codeFromTestStrategySecond,
                  duration: 10,
                ),
                TestStrategy(
                  code: codeFromTestStrategyThird,
                  duration: 5,
                ),
              ],
              senderNumber: senderNumber,
            ),
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          expect(controller.text, equals(codeFromTestStrategyThird));
        },
      );

      test(
        'If there is a PlatformException(code: 408)(Timeout exception) in the '
        'startListenUserConsent method, the onTimeOutException method must be called',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);
          when(() => otpInteractor.startListenUserConsent(any())).thenAnswer(
            (invocation) => Future.value(),
          );
          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          await controller.startListenUserConsent(
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
            strategies: [
              TestStrategyWithPlatformException(),
            ],
            senderNumber: senderNumber,
          );

          verify(() => onTimeOutException()).called(1);
        },
      );

      test(
        'If there is a any Exception(excluding timeout error) in the '
        'startListenUserConsent method, the handleError method must be called',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);
          when(() => otpInteractor.startListenUserConsent(any()))
              .thenAnswer((invocation) => Future.value());
          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          await controller.startListenUserConsent(
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
            strategies: [
              TestStrategyWithException(),
            ],
            senderNumber: senderNumber,
          );

          verify(() => onException(any())).called(1);
        },
      );

      test(
        'If there is a any Exception(excluding timeout error) in the '
        'startListenUserConsent method, the handleError method must be called',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);
          when(() => otpInteractor.startListenUserConsent(any()))
              .thenAnswer((invocation) => Future.value());
          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          expect(
            () async => controller.startListenUserConsent(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              strategies: [
                TestStrategyWithUnexpectedException(),
              ],
              senderNumber: senderNumber,
            ),
            throwsException,
          );
        },
      );
    },
  );

  group(
    'Call method startListenRetriever on OTPInteractor',
    () {
      test(
        'The method startListenRetriever on otpInteractor must be called',
        () async {
          when(() => otpInteractor.startListenRetriever()).thenAnswer(
            (invocation) => Future.value('Your code is $codeFromOTPInteractor'),
          );

          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          await controller.startListenRetriever(
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
            additionalStrategies: [TestStrategy(code: testCode)],
          );

          verify(() => otpInteractor.startListenRetriever()).called(1);
        },
      );

      test(
        'If otpInteractor faster then other sends a code, the controller.text must be equal to this code',
        () async {
          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          when(() => otpInteractor.startListenRetriever())
              .thenAnswer((invocation) => Future.value(codeFromOTPInteractor));

          unawaited(
            controller.startListenRetriever(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              additionalStrategies: [
                TestStrategy(code: codeFromTestStrategyFirst),
              ],
            ),
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          expect(controller.text, equals(codeFromOTPInteractor));

          verify(() => otpInteractor.startListenRetriever()).called(1);
        },
      );

      test(
        'If strategy faster then startListenUserConsent, should use code from strategy',
        () async {
          when(() => otpInteractor.startListenRetriever()).thenAnswer(
            (invocation) => Future.delayed(
              const Duration(milliseconds: 20),
              () => codeFromOTPInteractor,
            ),
          );

          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          unawaited(
            controller.startListenRetriever(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              additionalStrategies: [
                TestStrategy(
                  code: codeFromTestStrategyFirst,
                  duration: 10,
                ),
              ],
            ),
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          expect(controller.text, equals(codeFromTestStrategyFirst));
        },
      );

      test(
        'Should use code from fastest source',
        () async {
          when(() => otpInteractor.startListenRetriever()).thenAnswer(
            (invocation) => Future.delayed(
              const Duration(milliseconds: 20),
              () => codeFromOTPInteractor,
            ),
          );

          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          unawaited(
            controller.startListenRetriever(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              additionalStrategies: [
                TestStrategy(
                  code: codeFromTestStrategyFirst,
                  duration: 15,
                ),
                TestStrategy(
                  code: codeFromTestStrategySecond,
                  duration: 10,
                ),
                TestStrategy(
                  code: codeFromTestStrategyThird,
                  duration: 5,
                ),
              ],
            ),
          );

          expect(controller.text, isEmpty);

          await _futureDelayed();

          expect(controller.text, equals(codeFromTestStrategyThird));
        },
      );

      test(
        'If there is a PlatformException(code: 408)(Timeout exception) in the '
        'startListenRetriever method, the onTimeOutException method must be called',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);
          when(() => otpInteractor.startListenRetriever())
              .thenAnswer((invocation) => Future.value());
          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          await controller.startListenRetriever(
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
            additionalStrategies: [
              // Strategy will throw PlatformException.
              TestStrategyWithPlatformException(),
            ],
          );

          verify(() => onTimeOutException()).called(1);
        },
      );

      test(
        'If there is a any Exception(excluding timeout error) in the '
        'startListenRetriever method, the handleError method must be called',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);
          when(() => otpInteractor.startListenRetriever())
              .thenAnswer((invocation) => Future.value());
          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          await controller.startListenRetriever(
            (code) {
              final exp = RegExp(r'(\d{5})');
              return exp.stringMatch(code ?? '') ?? '';
            },
            additionalStrategies: [
              // Strategy will throw Exception.
              TestStrategyWithException(),
            ],
          );

          verify(() => onException(any())).called(1);
        },
      );

      test(
        'If there is a any Unexpected exception in the '
        'startListenRetriever method shuold throw Ecxeption',
        () async {
          when(() => platformWrapper.isAndroid).thenReturn(false);
          when(() => otpInteractor.startListenRetriever())
              .thenAnswer((invocation) => Future.value());
          when(() => otpInteractor.stopListenForCode())
              .thenAnswer((invocation) => Future.value());

          expect(
            () async => controller.startListenRetriever(
              (code) {
                final exp = RegExp(r'(\d{5})');
                return exp.stringMatch(code ?? '') ?? '';
              },
              additionalStrategies: [
                // Strategy will throw AssertionError.
                TestStrategyWithUnexpectedException(),
              ],
            ),
            throwsException,
          );
        },
      );
    },
  );

  test(
    'Call stopListen method on OTPTextEditController should call OTPInteractor.stopListenForCode',
    () async {
      when(() => otpInteractor.stopListenForCode())
          .thenAnswer((invocation) => Future.value());

      await controller.stopListen();

      verify(() => otpInteractor.stopListenForCode()).called(1);
    },
  );
}

class TestStrategy extends OTPStrategy {
  final dynamic code;
  final int _duration;

  TestStrategy({
    this.code,
    int? duration,
  }) : _duration = duration ?? 300;

  @override
  Future<String> listenForCode() {
    return Future.delayed(
      Duration(milliseconds: _duration),
      () => 'Your code is $code',
    );
  }
}

class TestStrategyWithPlatformException extends OTPStrategy {
  @override
  Future<String> listenForCode() {
    return Future.error(PlatformException(code: '408'));
  }
}

class TestStrategyWithException extends OTPStrategy {
  @override
  Future<String> listenForCode() {
    return Future.error(Exception());
  }
}

class TestStrategyWithUnexpectedException extends OTPStrategy {
  @override
  Future<String> listenForCode() {
    return Future.error(AssertionError());
  }
}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockPlatformWrapper extends Mock implements PlatformWrapper {}

class MockOTPInteractor extends Mock implements OTPInteractor {}

class MockOnTimeoutException extends Mock {
  void call();
}

class MockOnException extends Mock {
  void call(Exception error);
}
