# Achọ

On device file search for mobile devices

## Description

This project is an on-device search application for mobile, primarily targeting the Android platform.

The objective is to extend semantic search functionalities to African languages on a common device such as the mobile phone. Semantic search functionalities are powered by embeddings, but the models that generate those embeddings often do not cover low-resource languages such as those spoken by Africans. They often tend to cover more global languages such as English, French, Spanish, etc.

## Getting Started

Toolchain required to run the application

### Toolchain

- [Rust](https://rust-lang.org/tools/install/)
- [Flutter](https://docs.flutter.dev/install)
- [Just](https://just.systems)
- [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/quickstart)

### Installing

```sh
git clone https://github.com/HAKSOAT/acho
cd acho
just prepare
```

### Executing program

- How to run the program
- Step-by-step bullets

```
code blocks for commands
```

## Architecture
_TBD_

## Limitations

As explained in the [architecture](#architecture) section, we ultimately chose **Flutter + Rust** for this project. That decision wasn’t arbitrary—we explored several alternatives, including Kotlin, Tauri, and other stacks, before settling on this combination.

In the early stages, the project was built with **Tauri**. Given our JavaScript background, this initially felt like the most convenient choice. However, as the project evolved, we started running into practical limitations.

One of the major issues was Tauri’s filesystem API. While functional, it felt restrictive and inconsistent for more advanced file operations. The abstraction layer often made simple tasks unnecessarily complex, and the ergonomics of the API did not scale well with the needs of a system that heavily interacts with the filesystem. This became a bottleneck rather than a productivity boost.

We eventually migrated to **Flutter**, integrated with Rust via **flutter_rust_bridge**. This shift gave us three key advantages:

1. **No platform-specific code overhead**
   Unlike Kotlin or native platform approaches, we avoided writing separate implementations for each platform. Flutter provided a unified UI layer, while Rust handled the core logic efficiently.

2. **A stronger and more predictable Rust integration**
   Compared to Tauri’s JavaScript-Rust bridge, flutter_rust_bridge offered a more robust, type-safe, and scalable way to expose Rust APIs to the UI layer. This significantly improved maintainability and performance.

3. We get to do the heavy lifting in Rust and easily link the two contexts, Flutter and Rust, without a lot of headache. 

In summary, while Tauri was a good starting point, its limitations—especially around filesystem handling and API ergonomics—made it unsuitable for the long-term goals of the project. Flutter + Rust provided a better balance of performance, developer experience, and architectural clarity.

## License 
The Project is released under the [Apache License, Version 2.0](./LICENSE)