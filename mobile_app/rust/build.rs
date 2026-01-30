fn main() {
    #[cfg(target_os = "android")]
    {
        // This tells the linker that we will provide libc++_shared.so at runtime
        println!("cargo:rustc-link-lib=c++_shared");
    }
}