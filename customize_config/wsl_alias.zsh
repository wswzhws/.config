function open() {
    if [ -z "$1" ]; then
        echo "Usage: open <file_or_directory>"
        return 1
    fi

    local path="$1"

    if [ ! -e "$path" ]; then
        echo "Error: File or directory does not exist."
        return 1
    fi

    local win_path=$(/usr/bin/wslpath -w "$path")

    if [ -d "$path" ]; then
        /mnt/c/Windows/explorer.exe "$win_path"
        return 0
    fi

    local ext="${path##*.}"
    ext="${ext:l}"  

    case "$ext" in
        html|htm)
            /mnt/c/Program\ Files\ \(x86\)/Microsoft/Edge/Application/msedge.exe "$win_path"
            ;;
        pdf)
            /mnt/c/Program\ Files\ \(x86\)/Microsoft/Edge/Application/msedge.exe "$win_path"
            ;;
        txt|log)
            less "$win_path"
            ;;
        png|jpg|jpeg|gif|bmp|svg)
            /mnt/c/Windows/System32/mspaint.exe "$win_path"
            ;;
        *)
            /mnt/c/Windows/explorer.exe "$win_path"  
            ;;
    esac
}

alias cdd="cd /mnt/c/Users/zheha/Downloads"
alias pwsh="pwsh.exe"

if [ -f ~/.config/customize_config/usbipd.zsh ]; then
    alias usbipd="~/.config/customize_config/usbipd.zsh"
fi
