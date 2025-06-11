#! /bin/bash

echo "Creating and formatting filesystem image..."
truncate -s 2G rootfs.ext4
mkfs.ext4 rootfs.ext4

echo "Mounting filesystem image..."
mkdir -p /mnt
sudo mount rootfs.ext4 /mnt

echo "Creating temporary container and exporting filesystem..."
docker create --name temp_python python:3
docker export temp_python | sudo tar -x -C /mnt
docker rm temp_python

echo "Unmounting filesystem..."
sudo umount /mnt

echo "Filesystem setup complete."