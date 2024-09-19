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
    return version.replace(":", "-").strip()

def convert_cargo_version_to_opam(version):
    def parse_version(ver):
        if ver.startswith('^'):
            ver = ver[1:]
            parts = ver.split('.')
            major = parts[0]
            if major.isdigit():
                return f'>= "{sanitize_version(ver)}" & < "{int(major) + 1}.0.0"'
            else:
                return f'>= "{sanitize_version(ver)}"'
        elif ver.startswith('~'):
            ver = ver[1:]
            parts = ver.split('.')
            major = parts[0]
            minor = parts[1] if len(parts) > 1 else '0'

            if major.isdigit() and int(major) > 0:
                return f'>= "{sanitize_version(ver)}" & < "{int(major) + 1}.0.0"'
            elif minor.isdigit():
                return f'>= "{sanitize_version(ver)}" & < "0.{int(minor) + 1}.0"'
            else:
                return f'>= "{sanitize_version(ver)}"'
        # TODO we might need to translate this into a range if the minor versions are ommitted
        elif ver.startswith('='):
            return f'= "{sanitize_version(ver[1:])}"'
        elif ver.startswith('>='):
            return f'>= "{sanitize_version(ver[2:])}"'
        elif ver.startswith('<='):
            return f'<= "{sanitize_version(ver[2:])}"'
        elif ver.startswith('>'):
            return f'> "{sanitize_version(ver[1:])}"'
        elif ver.startswith('<'):
            return f'< "{sanitize_version(ver[1:])}"'
        else:
            return f'"{sanitize_version(ver)}"'

    parts = version.split(', ')
    opam_versions = [parse_version(part) for part in parts]
    return "& ".join(opam_versions)

def convert_dep_to_opam(dep):
    pkg = dep.get('package', dep['name'])
    ver = dep.get('req', '*')
    #print(pkg, ver)
    opam_version = convert_cargo_version_to_opam(ver)
    #print(opam_version)
    if opam_version == '*':
        return f'"{sanitize_package_name(pkg)}"'
    else:
        return f'"{sanitize_package_name(pkg)}" {{{opam_version}}}'

def process_crate(crate_path):
    with open(crate_path, 'r') as f:
        crate_lines = f.readlines()
    
    print(f"Generating Opam files for {crate_path}")
    for line in crate_lines:
        version = json.loads(line)
        
        pkg_name = version['name']
        version_num = version['vers']
        dependencies = version['deps']
        if version['yanked']:
            continue
        
        package_depends = []
        package_depopts = []
        package_conflicts = []
        
        for dep in dependencies:
            dep_entry = convert_dep_to_opam(dep)
            if dep['optional']:
                package_depopts.append(dep_entry)
            elif dep['kind'] == 'normal' or dep['kind'] is None:
                package_depends.append(dep_entry)
            elif dep['kind'] == 'conflict':
                package_conflicts.append(convert_dep_to_opam(dep))
        
        package_depends = sorted(set(package_depends))
        package_depopts = sorted(set(package_depopts))
        package_conflicts = sorted(set(package_conflicts))
        formatted_depends = '\n  '.join(package_depends) if package_depends else ''
        formatted_depopts = '\n  '.join(package_depopts) if package_depopts else ''
        formatted_conflicts = '\n  '.join(package_conflicts) if package_conflicts else ''
        opam_depends = f'\ndepends: [\n  {formatted_depends}\n]' if formatted_depends else ''
        opam_depopts = f'\ndepopts: [\n  {formatted_depopts}\n]' if formatted_depopts else ''
        opam_conflicts = f'\nconflicts: [\n  {formatted_conflicts}\n]' if formatted_conflicts else ''
        
        opam_template = """opam-version: "2.0"
build: [
  ["sh" "-c" "cargo install --vers {version_num} {pkg_name}"]
]
remove: [
  ["sh" "-c" "cargo uninstall {pkg_name}"]
]{depends}{depopts}{conflicts}
x-multiple-versions: true
"""
        
        opam_content = opam_template.format(
            version_num=version_num,
            pkg_name=pkg_name,
            depends=opam_depends,
            depopts=opam_depopts,
            conflicts=opam_conflicts
        )
        
        pkg_name_sanitized = sanitize_package_name(pkg_name)
        opam_pkg_dir = os.path.join(base_dir, pkg_name_sanitized)
        opam_version_dir = os.path.join(opam_pkg_dir, f"{pkg_name_sanitized}.{sanitize_version(version_num)}")
        os.makedirs(opam_version_dir, exist_ok=True)
        opam_file_path = os.path.join(opam_version_dir, 'opam')
        with open(opam_file_path, 'w') as opam_file:
            opam_file.write(opam_content)

for crate_path in glob.glob(os.path.join(index_dir, '**/*'), recursive=True):
    if os.path.isfile(crate_path) and os.path.basename(crate_path) not in ['config.json', 'README.md']:
        process_crate(crate_path)
