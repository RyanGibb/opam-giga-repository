import os
import tarfile

script_dir = os.path.dirname(os.path.abspath(__file__))
cache_dir = os.path.join(script_dir, '../../cached/apk')
versions_file = os.path.join(cache_dir, 'versions.txt')
base_dir = os.path.join(script_dir, '../../packages')
os.makedirs(base_dir, exist_ok=True)

def parse_provides_entry(entry):
    if '=' in entry:
        name, version = entry.split('=', 1)
        return name.strip(), version.strip()
    else:
        name = entry
        version = None
        return name.strip(), version

with open(versions_file, 'r') as vf:
    packages = {}
    for version in vf:
        alpine_version = version.strip()
        print(alpine_version)
        apkindex_path = os.path.join(cache_dir, f"{alpine_version}-APKINDEX.tar.gz")
        with tarfile.open(apkindex_path, 'r:gz') as index_tar:
            index_file = index_tar.extractfile('APKINDEX')
            if index_file:
                index_content = index_file.read().decode()
            else:
                print(f"error reading {apkindex_path}")
                exit(1)

        pkg = None
        # if two versions of alpine provide the same package version, we will use the later one
        for line in index_content.splitlines():
            if line.startswith('P:'):
                pkg = line[2:].strip()
            if line.startswith('V:') and pkg:
                ver = line[2:].strip()
                if (pkg, ver) in packages:
                    packages[(pkg,ver)].append(alpine_version)
                else:
                    packages[(pkg,ver)]=[alpine_version]
    for (pkg,ver), v in packages.items():
        if len(v) > 1:
            print(f"{pkg}.{ver} in {v}")

