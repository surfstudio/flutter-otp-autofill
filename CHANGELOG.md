# Changelog

## 3.0.4

* Correct logo position.

## 3.0.3

* Rebranding.

## 3.0.2

* Fix SmsRetrieverBroadcastReceiver on Android 14.

## 3.0.1

* Fix Android App crash on Android version 14.

## 3.0.0

* Breaking: Upgraded phone number hint API. Now may require updating Google Services on the device.
* Added base test case for package testing.
* Fix example of project.
* Fix Android App crash when phone allowed two SMS at the same time.

## 2.1.1

* Fixed example

## 2.1.0

* Change API: `startListenUserConsent` and `startListenRetriever` returns Future

## 2.0.0

* Static methods of OTPInteractor have been removed. Improved dependency passing.

## 1.1.0-dev.1

* Make native Android receivers null after unregister. (minor)
* Add `autoStop` param to `OTPTextEditController`. (minor)
* Make `OTPTextEditController`'s `onCodeReceive` non-required. (minor)

## 1.0.2

* Stable release

## 1.0.2-dev.1

* Apply new lint rules.

## 1.0.1

* Fix android build bug related on null-safety.
* Update readme.

## 1.0.0

* Migrate this package to null safety.

## 0.0.1-dev.4

* fix platformException on TimeOut

## 0.0.1 - Released

* add SMS Retriever API support
* add SMS User Consent API support
* add OTPStrategy for another OTP code input
