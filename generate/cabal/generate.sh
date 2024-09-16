#!/bin/bash

script_dir="$(dirname "$0")"
cabal_repo="${script_dir}/../../cached/cabal/repo"
opam_repo="${script_dir}/../../packages"

for package_dir in $cabal_repo/*; do
  package_name=$(basename $package_dir)
  for version_dir in $package_dir/*; do
    version=$(basename $version_dir)
    if [ $version == "preferred-versions" ]; then
      continue
    fi
    cabal_file="$version_dir/$package_name.cabal"
    new_package_name="cabal-$package_name"
    opam_package_dir="$opam_repo/$new_package_name/${new_package_name}.$version"
    mkdir -p $opam_package_dir
	$script_dir/cabal2opam $cabal_file > $opam_package_dir/opam
  done
done
