#!/usr/bin/env bash
set -euo pipefail

CNI_BIN_DIR="/opt/cni/bin"
CNI_CONF_DIR="/etc/cni/conf.d"

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo "Docker already installed, skipping..."
        return
    fi
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh ./get-docker.sh
    rm get-docker.sh
}

install_dependencies() {
    apt install -y golang-go git make
}

install_firecracker() {
    wget https://github.com/firecracker-microvm/firecracker/releases/download/v1.11.0/firecracker-v1.11.0-x86_64.tgz
    tar -xzf firecracker-v1.11.0-x86_64.tgz
    sudo cp release-v1.11.0-x86_64/firecracker-v1.11.0-x86_64 /usr/bin/firecracker
    sudo rm -rf release-v1.11.0-x86_64 firecracker-v1.11.0-x86_64.tgz
}

fetch_kernel() {
    local arch latest kernel_url kernel_file
    arch="$(uname -m)"
    echo "Detecting architecture: $arch"
    echo "Fetching latest kernel version..."
    latest="$(wget "http://spec.ccfc.min.s3.amazonaws.com/?prefix=firecracker-ci/v1.11/${arch}/vmlinux-6.1&list-type=2" -O - 2>/dev/null | grep -oP "(?<=<Key>)(firecracker-ci/v1.11/${arch}/vmlinux-6\.1\.[0-9]{1,3})(?=</Key>)" | tail -n1)"
    if [ -z "$latest" ]; then
        echo "Failed to determine latest kernel key" >&2
        exit 1
    fi
    kernel_url="https://s3.amazonaws.com/spec.ccfc.min/${latest}"
    kernel_file="${latest##*/}"

    if [ -f "$kernel_file" ]; then
        echo "Kernel $kernel_file already present, skipping download."
        return
    fi

    echo "Downloading kernel: $kernel_url"
    wget "$kernel_url" -O "$kernel_file"
    echo "Kernel downloaded to $kernel_file"
}

tidy_go_modules() {
    go mod tidy
}

ensure_cni_resolv_conf() {
    local host_resolv="/etc/resolv.conf"
    local cni_dir="/etc/cni"
    local target="$cni_dir/resolv.conf"

    if [ -f "$target" ]; then
        echo "CNI resolv.conf already present."
        return
    fi

    echo "Creating /etc/cni/resolv.conf..."
    sudo mkdir -p "$cni_dir"
    if [ -f "$host_resolv" ]; then
        sudo cp "$host_resolv" "$target"
    else
        echo "Warning: /etc/resolv.conf missing, writing fallback DNS entry."
        echo "nameserver 8.8.8.8" | sudo tee "$target" >/dev/null
    fi
}

build_cni_plugins() {
    echo "Cloning and building CNI plugins..."
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://github.com/containernetworking/plugins "$tmpdir/plugins"
    pushd "$tmpdir/plugins" >/dev/null
    bash build_linux.sh
    sudo mkdir -p "$CNI_BIN_DIR"
    sudo cp bin/* "$CNI_BIN_DIR/"
    popd >/dev/null
    rm -rf "$tmpdir"
    echo "CNI plugins built and installed"
}

setup_cni_config() {
    echo "Setting up CNI configuration..."
    sudo mkdir -p "$CNI_CONF_DIR"
    sudo cp ./fcnet.conflist "$CNI_CONF_DIR/fcnet.conflist"
    echo "CNI configuration copied to $CNI_CONF_DIR"
}

build_tc_redirect() {
    echo "Cloning and building tc-redirect-tap..."
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://github.com/awslabs/tc-redirect-tap "$tmpdir/tc-redirect-tap"
    pushd "$tmpdir/tc-redirect-tap" >/dev/null
    make
    sudo mkdir -p "$CNI_BIN_DIR"
    sudo cp tc-redirect-tap "$CNI_BIN_DIR/"
    popd >/dev/null
    rm -rf "$tmpdir"
    echo "tc-redirect-tap built and installed"
}

install_docker
install_dependencies
install_firecracker
fetch_kernel
tidy_go_modules
ensure_cni_resolv_conf
build_cni_plugins
build_tc_redirect
setup_cni_config
