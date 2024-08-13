.PHONY: all clean debian alpine cargo opam

all: debian alpine cargo opam repo

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

opam:
	@echo "Generating Opam packages..."
	@if [ ! -d cached/opam-repository ]; then \
		git clone --depth 1 https://github.com/ocaml/opam-repository.git cached/opam-repository; \
	else \
		echo "cached/opam-repository already exists, skipping clone."; \
	fi
	# requires opam_translation to be built
	cd generate/opam_translation; dune exec ./main.exe ../../cached/opam-repository/packages ../../packages

repo:
	@echo "Generating repo file"
	echo 'opam-version: "2.0"' > repo

clean:
	@echo "Cleaning..."
	rm -rf packages
	rm repo

