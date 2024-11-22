import os
import tarfile

script_dir = os.path.dirname(os.path.abspath(__file__))
cache_dir = os.path.join(script_dir, '../../cached/deb')
versions_file = os.path.join(cache_dir, 'versions.txt')
base_dir = os.path.join(script_dir, '../../packages')
os.makedirs(base_dir, exist_ok=True)

with open(versions_file, 'r') as vf:
    packages = {}
    for version in vf:
        debian_version = version.strip()
        print(debian_version)

        packages_path = os.path.join(cache_dir, f"{debian_version}/Packages")
        with open(packages_path, 'r') as f:
            packages_content = f.read()

        pkg = None
        packages = {}
        for line in packages_content.splitlines():
            if line.startswith('Package:'):
                pkg = line[len('Package:'):].strip()
            elif line.startswith('Version:') and pkg:
                ver = line[len('Version:'):].strip()
                if (pkg, ver) in packages:
                    packages[(pkg,ver)].append(debian_version)
                else:
                    print(pkg,ver)
                    packages[(pkg,ver)]=[debian_version]
    for (pkg,ver), v in packages.items():
        if len(v) > 1:
            print(f"{pkg}.{ver} in {v}")

