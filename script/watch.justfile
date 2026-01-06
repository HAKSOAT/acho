#!/usr/bin/env sh


watch target:
    @echo "Watching {{target}} for changes"
    @just "watch-{{target}}"

[working-directory: 'mobile']
@watch-android: 
    just android-watch

[working-directory: 'mobile']
@watch-ios:
    npm run tauri ios dev 'iphone 15'

[working-directory: 'mobile']
@watch-desktop:
    npm run tauri dev 

[working-directory: 'mobile']
@watch-frontend: 
    npm run dev 

