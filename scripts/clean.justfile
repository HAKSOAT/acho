clean target:
    #!/usr/bin/env sh
    
    elif [ "{{target}}" = "mobile" ]; then \
        cd "{{APP_DIR}}/src-tauri" && cargo clean
    if [ "{{target}}" = "all" ]; then \
        just clean web
        just clean server
        just clean app 
    else 
        echo "Invalid {{target}} use one of mobile,piper,lib"
    fi
