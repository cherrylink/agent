#!/bin/sh
# 目标目录
NZ_BASE_PATH="/opt/nezha"
NZ_AGENT_PATH="${NZ_BASE_PATH}/agent"

red='\033[0;31m'; green='\033[0;32m'; yellow='\033[0;33m'; plain='\033[0m'
err(){ printf "${red}%s${plain}\n" "$*" >&2; }
success(){ printf "${green}%s${plain}\n" "$*"; }
info(){ printf "${yellow}%s${plain}\n" "$*"; }

sudo(){ [ "$(id -ru)" -eq 0 ] && "$@" || command sudo "$@"; }

deps_check(){
    for dep in curl unzip grep; do command -v "$dep" >/dev/null 2>&1 || \
        { err "Missing $dep"; exit 1; }; done
}

env_check(){
    case "$(uname -m)" in
        amd64|x86_64) os_arch="amd64";;
        i386|i686)    os_arch="386";;
        aarch64|arm64)os_arch="arm64";;
        *) err "Unsupported arch"; exit 1;;
    esac
    case "$(uname)" in
        *Linux*)  os="linux";;
        *Darwin*) os="darwin";;
        *) err "Unsupported OS"; exit 1;;
    esac
}

init(){ deps_check; env_check; }

install(){
    echo "Installing..."
    # 固定下载地址
    NZ_AGENT_URL="https://oss.clash.ee/nezha/nezha-agent_${os}_${os_arch}.zip"

    curl --max-time 60 -fsSL "$NZ_AGENT_URL" -o /tmp/nezha-agent.zip \
        || { err "Download failed"; exit 1; }

    sudo mkdir -p "$NZ_AGENT_PATH"
    sudo unzip -qo /tmp/nezha-agent.zip -d "$NZ_AGENT_PATH"
    sudo rm -f  /tmp/nezha-agent.zip

    # 生成唯一 config 名称
    path="$NZ_AGENT_PATH/config.yml"
    [ -f "$path" ] && path="$NZ_AGENT_PATH/config-$(tr -dc a-z0-9 </dev/urandom | head -c5).yml"

    [ -z "$NZ_SERVER" ] && { err "NZ_SERVER empty"; exit 1; }
    [ -z "$NZ_CLIENT_SECRET" ] && { err "NZ_CLIENT_SECRET empty"; exit 1; }

    # 默认禁用自动更新
    : ${NZ_DISABLE_AUTO_UPDATE:=true}
    : ${NZ_DISABLE_FORCE_UPDATE:=true}
    : ${NZ_NAME:=}          # 服务器显示名称（可选）
    : ${NZ_GROUP:=}         # 服务器分组名称（可选）


    env="NZ_UUID=$NZ_UUID NZ_SERVER=$NZ_SERVER NZ_CLIENT_SECRET=$NZ_CLIENT_SECRET \
    NZ_TLS=$NZ_TLS NZ_DISABLE_AUTO_UPDATE=$NZ_DISABLE_AUTO_UPDATE \
    NZ_DISABLE_FORCE_UPDATE=$NZ_DISABLE_FORCE_UPDATE"

    sudo "$NZ_AGENT_PATH/nezha-agent" service -c "$path" uninstall >/dev/null 2>&1
    sudo env $env "$NZ_AGENT_PATH/nezha-agent" service -c "$path" install \
        -n "$NZ_NAME" -g "$NZ_GROUP" \
    && success "nezha-agent successfully installed" \
    || { err "Install failed"; sudo "$NZ_AGENT_PATH/nezha-agent" service -c "$path" uninstall; }
}

uninstall(){
    find "$NZ_AGENT_PATH" -type f -name "*config*.yml" | while read -r f; do
        sudo "$NZ_AGENT_PATH/nezha-agent" service -c "$f" uninstall
        sudo rm -f "$f"
    done
    info "Uninstallation completed."
}

[ "$1" = "uninstall" ] && { uninstall; exit; }
init; install