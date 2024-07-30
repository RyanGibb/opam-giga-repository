.PHONY: all clean debian alpine cargo

all: debian alpine cargo repo

debian:
	@echo "Generating Debian packages..."
	python3 generate/deb/generate.py

alpine:
	@echo "Generating Alpine packages..."
	python3 generate/apk/generate.py

cargo:
	@echo "Generating Cargo packages..."
	@if [ ! -d cached/cargo ]; then \
		git clone --depth 1 https://github.com/rust-lang/crates.io-index.git cached/cargo; \
	else \
		echo "cached/cargo already exists, skipping clone."; \
	fi
	python3 generate/cargo/generate.py

repo:
	@echo "Generating repo file"
	echo 'opam-version: "2.0"' > repo

clean:
	@echo "Cleaning..."
	rm -rf packages
	rm repo

