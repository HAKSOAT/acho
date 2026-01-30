# Introduction

Acho is an on-device file search system designed primarily for the Android platform, optimized for low-latency retrieval, privacy preservation, and scalable performance. Its architecture spans five core technical domains: contextual search, file system access, embedding and inference performance, security, developer experience and User experience.

Subsequent sections addresses distinct set of constraints, strengths, and challenges inherent to building for mobile environments; The choice of technology stack, the desired user and developer experience including limited computational resources, strict sandboxing, real-time responsiveness; the lessons learned and the overall experience.

## Contextual search

## File system

File system access significantly influenced the choice of framework. At the outset, Tauri
appeared well-suited to many of the project’s requirements due to its lightweight architecture and JavaScript–Rust interoperability. However, two critical limitations emerged during implementation.

First, Tauri enforces restrictive file system access boundaries that complicate deep, recursive traversal and low-level file metadata inspection—capabilities that are fundamental to building a performant on-device search index. Second, despite its Rust backend, achieving native-grade performance characteristics and platform-consistent user experience on Android proved challenging, particularly under the latency constraints required for real-time file search.

## Embedding and inference

## Security

Acho leverages Rust’s strong ownership model, expressive type system, and compile-time guarantees to eliminate entire classes of memory safety vulnerabilities, including use-after-free, data races, and null pointer dereferencing. On the application layer, Dart’s sound null safety further enforces correctness by preventing invalid state propagation across UI and business logic boundaries. Together, this multi-language safety model provides a robust defense against memory corruption and undefined behavior, which is especially critical in an on-device system handling sensitive user data.

## Developer Experience and User Experience

Flutter provides a mature, production-grade toolchain with a highly optimized rendering pipeline and a consistent cross-platform abstraction layer. Its declarative UI model enables rapid iteration while maintaining predictable performance characteristics. Combined with a hot-reload–driven development workflow and strong ecosystem support, Flutter significantly reduces development friction without compromising user experience. From the user’s perspective, this results in a responsive, native-feeling interface with smooth interactions, even under the computational demands of real-time file indexing and search.
