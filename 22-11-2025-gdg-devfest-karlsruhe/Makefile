.PHONY: build setup run

build:
	@echo "Building Go binary and setting up filesystem..."
	bash fs.sh

setup:
	@echo "Running setup script..."
	bash setup.sh

run:
	@echo "Running Go program..."
	go run main.go 

forward:
	socat TCP-LISTEN:8888,fork,reuseaddr TCP:$$(ip neigh show dev fcnet0 | grep -v FAILED | awk '{print $$1}' | head -n1):8888