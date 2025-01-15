.PHONY: all clean debian alpine cargo opam test

all: debian alpine cargo opam cabal repo

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

cabal:
	@if [ ! -f cached/cabal/01-index.tar ]; then \
		mkdir -p cached/cabal; \
		curl https://hackage.haskell.org/01-index.tar --output cached/cabal/01-index.tar; \
	else \
		echo "cached/cabal/01-index.tar already exists, skipping."; \
	fi
	@if [ ! -d cached/cabal/repo ]; then \
		mkdir -p cached/cabal/repo; \
		tar -xvf cached/cabal/01-index.tar -C cached/cabal/repo/; \
	else \
		echo "cached/cabal/repo already exists, skipping."; \
	fi
	generate/cabal/generate.sh

pacman:
	@echo "Generating Pacman packages..."
	@if [ ! -d cached/pacman ]; then \
		./generate/pacman/download_index.sh \
	else \
		echo "cached/pacman already exists, skipping download."; \
	fi
	# requires pacman to be built
	cd generate/pacman; dune exec ./main.exe ../../cached/pacman/ ../../packages

repo:
	@echo "Generating repo file"
	echo 'opam-version: "2.0"' > repo

test:
	test/test_all_packages.sh

clean:
	@echo "Cleaning..."
	rm -rf packages
	rm repo
	rm test/log

