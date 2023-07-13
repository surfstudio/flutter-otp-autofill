# Testing steps

> These steps is example of testing package`s current stability.

1. Proceed to [example](../example/) directory of current repository.
2. Use [FVM](https://fvm.app/) to install current Flutter version for this package, if your global version differs.
   1. `fvm use`
   2. Setup your IDE to use project`s Flutter version by [this](https://fvm.app/docs/getting_started/configuration/#ide) guide
3. Open project with your preferred IDE
4. In [main.dart](https://github.com/surfstudio/flutter-otp-autofill/blob/main/example/lib/main.dart#L55) file comment line with SampleStrategy, to use realtime SMS handling.
   - `SampleStrategy` imitating custom strategy of receiving confirmation code, i.e. by receiving silent push notification. 
5. Launch application.
6. Pick example application`s signature from debug console log.
   - ![Image that show app signature in debug console](assets/testing/signature-code.png)
7. Send SMS message contains 5-symbol code, including all numbers.
   - If you are using Android Emulator, you can use built-in functionality to emulate calls and SMS-messages, by pressing `Extended Controls` and select `Phone` option in side menu.
8. In time SMS message has been received by your device/emulator, you should see alert, asking permission to read SMS message with code and actual message, that will be used to parse code.
    ![Screenshot of emulator with shown dialog of receiving confirmation code](assets/testing/sms-received.png)
9.  By pressing "Allow" code that was shown on alert, inserts in actual field in example app.
    ![Screenshot of emulator after pressing "Allow" button](assets/testing/sms-code-paste.png)
    - By pressing deny nothing will be inserted in field and dialog will be closed.