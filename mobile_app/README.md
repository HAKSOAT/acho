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

This app spawns compuation to an isolate to prevent U.I jank, and further intensive computation including Semantic similarity search, and keyword search to Rust using the flutter_rust_bridge plugin. 

# 🏗️ Manual Build & Compile Guide

Use this sequence whenever you modify your Rust code (`.rs` files). This process ensures the **Dart code** (Frontend) and **Rust binary** (Backend) are perfectly synchronized.

---

### 1. Set Environment Variables
Ensure your terminal knows where NDK 27 is. Run this once per terminal session (or save it to your `~/.zshrc`).

```bash
# Set path to NDK 27
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/27.0.12077973
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
```

We use ndk 27 due to compatibility with ort crate

### 2. Generate bindings for Rust (containing functionality of keyword search and semantic search)

from location `acho/mobile_app`

```bash
flutter_rust_bridge_codegen generate 
```

### 3. Compile the .so library for

```bash
cd rust

# Clean previous builds to force a fresh hash (Recommended)
cargo clean

# Build Release version
cargo build --target aarch64-linux-android --release

cd ..
```

### 4 . Copy the fresh binary to a locaiton for the android target

from location `acho/mobile_app`

```bash 
cp rust/target/aarch64-linux-android/release/librust_lib_mobile_app.so android/app/src/main/jniLibs/arm64-v8a/
```

### 5. Verify the content of the jniLibs Folder contains the required .so files 

```bash
ls -l android/app/src/main/jniLibs/arm64-v8a/
```

- libc++_shared.so (From NDK 27)
- libonnxruntime.so (From onnxruntime-android-1.23.2 AAR or Gradle)
- librust_lib_mobile_app.so


### 6. Most importantly ensure the models and tokenizers are in the Downloads folder on device (TODO: better way of deploying models)

These three files :
- model.onnx
- model.onnx_data
- tokenizer.json
