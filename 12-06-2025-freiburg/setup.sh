apt install -y go make

wget https://github.com/firecracker-microvm/firecracker/releases/download/v1.11.0/firecracker-v1.11.0-x86_64.tgz
tar -xzf firecracker-v1.11.0-x86_64.tgz
cp release-v1.11.0-x86_64/firecracker-v1.11.0-x86_64 /usr/bin/firecracker

rm -rf release-v1.11.0-x86_64 firecracker-v1.11.0-x86_64.tgz

go mod tidy
