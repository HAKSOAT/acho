# mobile_app

To run acho on your machine: 

- Install Android Studio
- Install Java 17
  - Configure flutter to use Java 17 because bundled Java 21 has bugs with the latest mac version (Tahoe) with
    For Mac:
      ```
      flutter config --jdk-dir="/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
    ```
    
    Path may differ for windows
- Configure a device (Android 16.0) in Tools > Device Manager. and start with the play button ( ▶)
![Screenshot 2026-01-17 at 12.25.49.png](../../../../Desktop/Screenshot%202026-01-17%20at%2012.25.49.png)
- `cd mobile_app`
- `flutter run` 