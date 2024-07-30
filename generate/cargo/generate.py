import os
import json
import glob

script_dir = os.path.dirname(os.path.abspath(__file__))
index_dir = os.path.join(script_dir, '../../cached/cargo')
base_dir = os.path.join(script_dir, '../../packages')
os.makedirs(base_dir, exist_ok=True)

def sanitize_package_name(name):
    if name == "opam":
        return "opam-rust"
    return "cargo-" + name.replace("/", "-").replace(":", "-").replace(".", "-")

def sanitize_version(version):
    return version.replace(":", "-")

def convert_dep_to_opam(dep):
    pkg, ver = dep['name'], dep.get('req', '*')
    if ver == '*':
        return f'"{sanitize_package_name(pkg)}"'
    else:
        return f'"{sanitize_package_name(pkg)}" {{= "{sanitize_version(ver)}"}}'

def process_crate(crate_path):
    with open(crate_path, 'r') as f:
        crate_lines = f.readlines()
    
    for line in crate_lines:
        version = json.loads(line)
        
        pkg_name = version['name']
        version_num = version['vers']
        dependencies = version['deps']
        
        package_depends = []
        package_conflicts = []
        
        for dep in dependencies:
            if dep['kind'] == 'normal' or dep['kind'] is None:
                package_depends.append(convert_dep_to_opam(dep))
            elif dep['kind'] == 'conflict':
                package_conflicts.append(convert_dep_to_opam(dep))
        
        package_depends = sorted(set(package_depends))
        package_conflicts = sorted(set(package_conflicts))
        formatted_depends = '\n  '.join(package_depends) if package_depends else ''
        formatted_conflicts = '\n  '.join(package_conflicts) if package_conflicts else ''
        opam_depends = f'\ndepends: [\n  {formatted_depends}\n]' if formatted_depends else ''
        opam_conflicts = f'\nconflicts: [\n  {formatted_conflicts}\n]' if formatted_conflicts else ''
        
        opam_template = """opam-version: "2.0"
build: [
  ["sh" "-c" "cargo install --vers {version_num} {pkg_name}"]
]
remove: [
  ["sh" "-c" "cargo uninstall {pkg_name}"]
]{depends}{conflicts}
"""
        
        opam_content = opam_template.format(
            version_num=version_num,
            pkg_name=pkg_name,
            depends=opam_depends,
            conflicts=opam_conflicts
        )
        
        pkg_name_sanitized = sanitize_package_name(pkg_name)
        opam_pkg_dir = os.path.join(base_dir, pkg_name_sanitized)
        opam_version_dir = os.path.join(opam_pkg_dir, f"{pkg_name_sanitized}.{sanitize_version(version_num)}")
        os.makedirs(opam_version_dir, exist_ok=True)
        opam_file_path = os.path.join(opam_version_dir, 'opam')
        with open(opam_file_path, 'w') as opam_file:
            opam_file.write(opam_content)
        
        print(f"Generated Opam file for {pkg_name} version {version_num}")

for crate_path in glob.glob(os.path.join(index_dir, '**/*'), recursive=True):
    if os.path.isfile(crate_path) and os.path.basename(crate_path) not in ['config.json', 'README.md']:
        process_crate(crate_path)
