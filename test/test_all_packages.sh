#!/usr/bin/env bash

script_dir="$(dirname "$0")"
repo_dir="${script_dir}/../packages/"
log_dir="${script_dir}/log"

mkdir -p "$log_dir"

test_command() {
    package_version="$1"
    package=$(echo "$package_version" | cut -d'.' -f1)
    version=$(echo "$package_version" | cut -d'.' -f2-)
    log_file="$log_dir/$package_version.log"
	echo $log_file
    
    echo "Testing installation of $package.$version..."
    
    if ~/opam-0install-solver/_build/default/bin/main.exe --repo "$repo_dir" "$package_version" 2>&1 > "$log_file"; then
        echo "Success: $package_version" | tee -a "$log_file"
    else
        echo "Failed: $package_version" | tee -a "$log_file"
    fi
}

export -f test_command
export log_dir repo_dir

find "$repo_dir" -mindepth 2 -maxdepth 2 -type d | while read version_dir; do
    version=$(basename "$version_dir")
    echo "$version"
done | parallel -j "$(nproc)" test_command {}

