import 'scripts/watch.justfile'
import 'scripts/clean.justfile'
import 'scripts/android.justfile'
import 'scripts/onnx.justfile'


# Alias
alias install := install-dependencies
alias config:= configure
alias w := watch
alias c := clean


# projects directories 
APP_DIR:='mobile'
LIB_DIR :='lib'

#>>  Default Shows the default commands 
default:
    @just --list --list-heading $'Available commands\n'

#>> execute all initial setup after cloning the project
configure:
    @just install-dependencies
    rustup target add aarch64-unknown-linux-gnu

        

#>> Dependency Setup
[doc('Install the application dependencies')]
install-dependencies:
    @echo "Installing dependencies"
    cargo install --git https://github.com/cpg314/cargo-group-imports
    cargo install cargo-sort
    cargo install cargo-watch
    brew install coreutils gnu-sed


generate-bindings:
    cd server && cargo test 
    rm -rf app/app/bindings 
    cp -r server/bindings app/app/bindings 



