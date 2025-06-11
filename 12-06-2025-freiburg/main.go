package main

import (
	"context"
	"os"

	"github.com/firecracker-microvm/firecracker-go-sdk"
	"github.com/firecracker-microvm/firecracker-go-sdk/client/models"
)

func main() {
	ctx := context.TODO()

	machine, err := firecracker.NewMachine(ctx, firecracker.Config{
		KernelImagePath: "./vmlinux",
		KernelArgs:      "console=ttyS0 pci=off reboot=k panic=1 init=/bin/python3",
		Drives: []models.Drive{{
			IsRootDevice: firecracker.Bool(true),
			IsReadOnly:   firecracker.Bool(false),
			PathOnHost:   firecracker.String("./rootfs.ext4"),
			DriveID:      firecracker.String("rootfs"),
		}},
		MachineCfg: models.MachineConfiguration{
			VcpuCount:  firecracker.Int64(1),
			MemSizeMib: firecracker.Int64(1024),
		},
		SocketPath: "./firecracker.sock",
	})
	if err != nil {
		panic(err)
	}

	if err := machine.Start(ctx); err != nil {
		panic(err)
	}

	<-make(chan os.Signal, 1)

	if err := machine.Shutdown(ctx); err != nil {
		panic(err)
	}
}
