#!/usr/bin/env bash

script_dir="$(dirname "$0")"
base_url="https://mirror.rackspace.com/archlinux"
dir="${script_dir}/../../cached/pacman"
repos=("core" "extra" "multilib")
arch="x86_64"

for repo in "${repos[@]}"; do
    repo_dir="${dir}/${repo}"
    mkdir -p "$repo_dir"
    echo "Creating directory: $repo_dir"
    if [[ ! -f "$repo_dir" ]]; then
        echo "Downloading ${repo}.db.tar.gz..."
		file="${dir}/${repo}.tar.gz"
        curl -L "${base_url}/${repo}/os/${arch}/${repo}.db.tar.gz" -o "$file"
        echo "Extracting $file to $repo_dir..."
        if ! tar -xzf "$file" -C "$repo_dir"; then
            echo "Error extracting $file"
            exit 1
        fi
	    rm "$file"
    else
        echo "Directory $repo_dir already exists, skipping download."
    fi
done
