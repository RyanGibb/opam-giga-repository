import os

script_dir = os.path.dirname(os.path.abspath(__file__))
cache_dir = os.path.join(script_dir, '../../cached/deb')
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

def sanitize_package_name(name):
    if name == "opam":
        return "opam-deb"
    return "deb-" + name.replace("/", "-").replace(":", "-").replace(".", "-")

def sanitize_version(version):
    return version.replace(":", "-")

def convert_dep_to_opam(dep):
    if ' (' in dep:
        pkg, ver = dep.split(' (')
        ver = ver.replace(')', '')
        operator, version = ver.split()
        operator = operator.replace('<<', '<')
        operator = operator.replace('>>', '>')
        constraint = f'{operator} "{sanitize_version(version)}"'
        return f'"{sanitize_package_name(pkg.strip()).strip()}" {{{constraint}}}'
    else:
        return f'"{sanitize_package_name(dep.strip()).strip()}"'

def parse_dependency(dep):
    if ' (' in dep:
        pkg, ver = dep.split(' (')
        return pkg.strip(), ver.replace(')', '').strip()
    else:
        return dep.strip(), None

def process_packages_file(debian_version):
    packages_path = os.path.join(cache_dir, f"{debian_version}/Packages")
    repo_url = f"http://ftp.debian.org/debian/"
    
    with open(packages_path, 'r') as f:
        packages_content = f.read()
    
    pkg = None
    packages = {}
    for line in packages_content.splitlines():
        if line.startswith('Package:'):
            pkg = line[len('Package:'):].strip()
            packages[pkg] = {}
            packages[pkg]["version"] = None
            packages[pkg]["dependencies"] = []
            packages[pkg]["provides"] = []
            packages[pkg]["conflicts"] = []
        elif line.startswith('Version:') and pkg:
            packages[pkg]["version"] = line[len('Version:'):].strip()
        elif line.startswith('Depends:') and pkg:
            dependencies = line[len('Depends:'):].strip().split(',')
            packages[pkg]["dependencies"] = [dep.strip() for dep in dependencies]
        elif line.startswith('Provides:') and pkg:
            provides = line[len('Provides:'):].strip().split(',')
            packages[pkg]["provides"] = [parse_provides_entry(provide.strip()) for provide in provides]
        elif line.startswith('Conflicts:') and pkg:
            conflicts = line[len('Conflicts:'):].strip().split(',')
            packages[pkg]["conflicts"] = [conflict.strip() for conflict in conflicts]
        elif line.startswith('Filename:') and pkg:
            filename = line[len('Filename:'):].strip()
            packages[pkg]["filename"] = filename

    if "libgcc-s1" in packages:
        del packages["libgcc-s1"]
    
    package_provides = {}
    for pkg in packages.keys():
        for provide_name, provide_version in packages[pkg]["provides"]:
            if provide_name not in packages:
                if provide_name in package_provides:
                    package_provides[provide_name].append(pkg)
                else:
                    package_provides[provide_name] = [pkg]
    
    for pkg in packages.keys():
        version = packages[pkg]["version"]
        deb_name = f"{pkg}_{version}_amd64"
        deb_url = os.path.join(repo_url, packages[pkg]["filename"])
        deps = packages[pkg]["dependencies"]
        confs = packages[pkg]["conflicts"]

        package_depends = []
        package_conflicts = []

        for dep in deps:
            if dep.startswith('!'):
                package_conflicts.append(convert_dep_to_opam(dep))
            elif '|' in dep:
                alternatives = dep.split('|')
                opam_alternatives = [convert_dep_to_opam(alt) for alt in alternatives if parse_dependency(alt)[0] != 'libgcc-s1']
                if opam_alternatives:
                    package_depends.append(f"({' | '.join(opam_alternatives)})")
            else:
                dep_name = dep.split('=')[0].split('>=')[0].split('<=')[0].split('<')[0].split('>')[0].split('~')[0].split('<<')[0].strip()
                if dep_name == "libgcc-s1":
                    continue
                if dep_name in packages:
                    package_depends.append(convert_dep_to_opam(dep))
                elif dep_name in package_provides:
                    providers = package_provides[dep_name]
                    if len(providers) == 1:
                        dep = providers[0]
                        package_depends.append(convert_dep_to_opam(providers[0]))
                    else:
                        package_depends.append(f"({' | '.join(convert_dep_to_opam(p) for p in providers)})")
                else:
                    package_depends.append(convert_dep_to_opam(dep))

        for conf in confs:
            package_conflicts.append(convert_dep_to_opam(conf))
        
        package_depends = sorted(set(package_depends))
        package_conflicts = sorted(set(package_conflicts))
        formatted_depends = '\n  '.join(package_depends) if package_depends else ''
        formatted_conflicts = '\n  '.join(package_conflicts) if package_conflicts else ''
        opam_depends = f'\ndepends: [\n  {formatted_depends}\n]' if formatted_depends else ''
        opam_conflicts = f'\nconflicts: [\n  {formatted_conflicts}\n]' if formatted_conflicts else ''
        opam_template = """opam-version: "2.0"
build: [
  ["sh" "-c" "sudo dpkg -i {deb_name}.deb"]
]
remove: [
  ["sh" "-c" "sudo dpkg -r {pkg}"]
]{depends}{conflicts}
extra-source "{deb_name}.deb" {{
  src: "{deb_url}"
}}
"""
        opam_content = opam_template.format(
            deb_name=deb_name,
            pkg=pkg,
            deb_url=deb_url,
            depends=opam_depends,
            conflicts=opam_conflicts
        )

        pkg_name = sanitize_package_name(pkg)
        opam_pkg_dir = os.path.join(base_dir, pkg_name)
        opam_version_dir = os.path.join(opam_pkg_dir, f"{pkg_name}.{sanitize_version(version)}")
        os.makedirs(opam_version_dir, exist_ok=True)
        opam_file_path = os.path.join(opam_version_dir, 'opam')
        with open(opam_file_path, 'w') as opam_file:
            opam_file.write(opam_content)

with open(versions_file, 'r') as vf:
    for version in vf:
        version = version.strip()
        print(version)
        process_packages_file(version)
