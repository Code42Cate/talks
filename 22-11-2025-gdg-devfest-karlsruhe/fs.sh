#! /bin/bash

echo "Creating and formatting filesystem image..."
truncate -s 2G rootfs.ext4
mkfs.ext4 rootfs.ext4

echo "Mounting filesystem image..."
mkdir -p /mnt
sudo mount rootfs.ext4 /mnt

echo "Creating temporary container and exporting filesystem..."
docker create --name temp_python jupyter/minimal-notebook
docker export temp_python | sudo tar -x -C /mnt
docker rm temp_python

echo "Writing init script..."
cat <<'EOF' | sudo tee /mnt/init-firecracker.sh >/dev/null
#!/bin/sh
export PATH=/opt/conda/bin:$PATH
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
EOF

sudo chmod +x /mnt/init-firecracker.sh
echo "nameserver 1.1.1.1" | sudo tee /mnt/etc/resolv.conf >/dev/null

echo "Unmounting filesystem..."
sudo umount /mnt

echo "Filesystem setup complete."