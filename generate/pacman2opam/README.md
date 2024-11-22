# pacman2opam

The Pacman repository is similar to opam repository.  One folder per package with a `desc` file.  The `desc` file follows a simple format of %variable% on one line with the content on the next lines.  The variable ends with an empty line.  Among other things, the package has variables for the things which it provides, the things which it depends upon and any conflicting packages.

- Some packages conflict with the thing they provide.  e.g. `mesa-amber` provides `mesa` but also conflicts with `mesa` all without version constraints.  I have modified the constraints to the conflicting packages: `pkg {!= version}`

- opam can't handle a package called `opam`.  Package `opam` has been excluded.

- Packages can depend upon other packages directly or other packages through the things which the package provides.

- Some package versions contain `:`, which is invalid in opam.  e.g. grub-2:2.12-3.  This is changed to `_`.

- Some package names contain `.`, which is invalid in opam.  e.g. libreadline.so.  This is changed to `_`.

- Package versions are often abbreviated.  e.g. version 256.6 could be written as 256.6-1.  Pacman considers these equal but opam considers them different.  Short versions have been updated to the longer form.

- Packages contain circular dependencies.  e.g. `pam` depends upon `systemd-libs`, which depends upon `libcap`, which depends upon `pam`.  These are detected and removed but this may affect the ability of the Pacman to install the package.

# Usage

Run this project with

```
dune exec -- pacman2opam
```

# Test with Ryan's solver

```
git clone https://github.com/RyanGibb/opam-0install-solver
dune exec -- bin/main.exe --repo ~/pacman2opam/archlinux/packages vim
```

# Test with Docker

```
docker run -v ~/pacman2opam/archlinux:/root/archlinux --rm -it archlinux bash
curl -L https://github.com/ocaml/opam/releases/download/2.2.1/opam-2.2.1-x86_64-linux -o /usr/bin/opam
chmod +x /usr/bin/opam
opam init -k local --bare --bypass-checks -a -y /root/archlinux
opam switch create archlinux --empty
OPAMJOBS=1 opam install vim -y
```

e.g.

```
[root@c28553596095 /]# OPAMJOBS=1 opam install vim -y
[WARNING] Running as root is not recommended
The following actions will be performed:
=== install 56 packages
  ∗ acl                  2.3.2-1                     [required by vim]
  ∗ audit                4.0.2-2                     [required by pam]
  ∗ bash                 5.2.037-1                   [required by gpm]
  ∗ e2fsprogs            1.47.1-4                    [required by krb5]
  ∗ filesystem           2024.04.07-1                [required by glibc]
  ∗ gcc-libs             14.2.1+r134+gab884fffe3fc-1 [required by systemd-libs]
  ∗ gdbm                 1.24-1                      [required by libsasl]
  ∗ glibc                2.40+r16+gaa533d58ff-2      [required by vim]
  ∗ gpm                  1.20.7.r38.ge82d1a6-6       [required by vim]
  ∗ iana-etc             20240814-1                  [required by filesystem]
  ∗ keyutils             1.6.3-3                     [required by krb5]
  ∗ krb5                 1.21.3-1                    [required by audit]
  ∗ libaudit_so          1-64                        [required by pam]
  ∗ libcap               2.70-1                      [required by systemd-libs]
  ∗ libcap-ng            0.8.5-2                     [required by audit]
  ∗ libcap-ng_so         0-64                        [required by audit]
  ∗ libcom_err_so        2-64                        [required by krb5]
  ∗ libcrypt_so          2-64                        [required by pam]
  ∗ libcrypto_so         3-64                        [required by libsasl]
  ∗ libevent             2.1.12-4                    [required by libverto]
  ∗ libgcrypt            1.11.0-2                    [required by vim]
  ∗ libgdbm_so           6-64                        [required by libsasl]
  ∗ libgpg-error         1.50-1                      [required by libgcrypt]
  ∗ libgssapi_krb5_so    2-64                        [required by audit]
  ∗ libkeyutils_so       1-64                        [required by krb5]
  ∗ libkrb5_so           3-64                        [required by audit]
  ∗ libldap              2.6.8-2                     [required by krb5]
  ∗ libncursesw_so       6-64                        [required by procps-ng]
  ∗ libnsl               2.0.1-1                     [required by pam]
  ∗ libreadline_so       8-64                        [required by bash]
  ∗ libsasl              2.1.28-5                    [required by libldap]
  ∗ libss_so             2-64                        [required by krb5]
  ∗ libtirpc             1.3.5-1                     [required by pam]
  ∗ libverto             0.3.2-5                     [required by libverto_so, libverto-module-base]
  ∗ libverto-module-base 1                           [required by krb5]
  ∗ libverto_so          1-64                        [required by krb5]
  ∗ libxcrypt            4.4.36-2                    [required by pam]
  ∗ linux-api-headers    6.10-1                      [required by glibc]
  ∗ lmdb                 0.9.33-1                    [required by krb5]
  ∗ lz4                  1_1.10.0-2                  [required by systemd-libs]
  ∗ ncurses              6.5-3                       [required by bash, procps-ng]
  ∗ openssl              3.3.2-1                     [required by krb5]
  ∗ pam                  1.6.1-3                     [required by libcap]
  ∗ pambase              20230918-2                  [required by pam]
  ∗ procps-ng            4.0.4-3                     [required by gpm]
  ∗ readline             8.2.013-1                   [required by bash]
  ∗ sh                   1                           [required by xz]
  ∗ sqlite               3.46.1-1                    [required by util-linux-libs]
  ∗ systemd-libs         256.6-1                     [required by procps-ng]
  ∗ tzdata               2024b-2                     [required by glibc]
  ∗ util-linux-libs      2.40.2-1                    [required by e2fsprogs]
  ∗ vim                  9.1.0764-1
  ∗ vim-runtime          9.1.0764-1                  [required by vim]
  ∗ xz                   5.6.3-1                     [required by systemd-libs]
  ∗ zlib                 1_1.3.1-2                   [required by vim]
  ∗ zstd                 1.5.6-1                     [required by systemd-libs]

<><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
⬇ retrieved acl.2.3.2-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/acl-2.3.2-1-x86_64.pkg.tar.zst)
⬇ retrieved audit.4.0.2-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/audit-4.0.2-2-x86_64.pkg.tar.zst)
⬇ retrieved filesystem.2024.04.07-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/filesystem-2024.04.07-1-any.pkg.tar.zst)
⬇ retrieved e2fsprogs.1.47.1-4  (https://mirror.rackspace.com/archlinux/core/os/x86_64/e2fsprogs-1.47.1-4-x86_64.pkg.tar.zst)
⬇ retrieved gdbm.1.24-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/gdbm-1.24-1-x86_64.pkg.tar.zst)
⬇ retrieved bash.5.2.037-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/bash-5.2.037-1-x86_64.pkg.tar.zst)
⬇ retrieved gpm.1.20.7.r38.ge82d1a6-6  (https://mirror.rackspace.com/archlinux/core/os/x86_64/gpm-1.20.7.r38.ge82d1a6-6-x86_64.pkg.tar.zst)
⬇ retrieved iana-etc.20240814-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/iana-etc-20240814-1-any.pkg.tar.zst)
∗ installed iana-etc.20240814-1
⬇ retrieved keyutils.1.6.3-3  (https://mirror.rackspace.com/archlinux/core/os/x86_64/keyutils-1.6.3-3-x86_64.pkg.tar.zst)
∗ installed filesystem.2024.04.07-1
⬇ retrieved glibc.2.40+r16+gaa533d58ff-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/glibc-2.40+r16+gaa533d58ff-2-x86_64.pkg.tar.zst)
⬇ retrieved krb5.1.21.3-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/krb5-1.21.3-1-x86_64.pkg.tar.zst)
⬇ retrieved libcap-ng.0.8.5-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libcap-ng-0.8.5-2-x86_64.pkg.tar.zst)
⬇ retrieved libcap.2.70-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libcap-2.70-1-x86_64.pkg.tar.zst)
⬇ retrieved libevent.2.1.12-4  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libevent-2.1.12-4-x86_64.pkg.tar.zst)
⬇ retrieved libgpg-error.1.50-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libgpg-error-1.50-1-x86_64.pkg.tar.zst)
⬇ retrieved libgcrypt.1.11.0-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libgcrypt-1.11.0-2-x86_64.pkg.tar.zst)
⬇ retrieved libnsl.2.0.1-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libnsl-2.0.1-1-x86_64.pkg.tar.zst)
⬇ retrieved libldap.2.6.8-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libldap-2.6.8-2-x86_64.pkg.tar.zst)
⬇ retrieved libsasl.2.1.28-5  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libsasl-2.1.28-5-x86_64.pkg.tar.zst)
⬇ retrieved libtirpc.1.3.5-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libtirpc-1.3.5-1-x86_64.pkg.tar.zst)
⬇ retrieved libverto.0.3.2-5  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libverto-0.3.2-5-x86_64.pkg.tar.zst)
⬇ retrieved libxcrypt.4.4.36-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/libxcrypt-4.4.36-2-x86_64.pkg.tar.zst)
⬇ retrieved lmdb.0.9.33-1  (https://mirror.rackspace.com/archlinux/extra/os/x86_64/lmdb-0.9.33-1-x86_64.pkg.tar.zst)
⬇ retrieved lz4.1_1.10.0-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/lz4-1:1.10.0-2-x86_64.pkg.tar.zst)
⬇ retrieved linux-api-headers.6.10-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/linux-api-headers-6.10-1-x86_64.pkg.tar.zst)
⬇ retrieved ncurses.6.5-3  (https://mirror.rackspace.com/archlinux/core/os/x86_64/ncurses-6.5-3-x86_64.pkg.tar.zst)
⬇ retrieved pam.1.6.1-3  (https://mirror.rackspace.com/archlinux/core/os/x86_64/pam-1.6.1-3-x86_64.pkg.tar.zst)
∗ installed linux-api-headers.6.10-1
⬇ retrieved pambase.20230918-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/pambase-20230918-2-any.pkg.tar.zst)
∗ installed pambase.20230918-2
⬇ retrieved openssl.3.3.2-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/openssl-3.3.2-1-x86_64.pkg.tar.zst)
⬇ retrieved procps-ng.4.0.4-3  (https://mirror.rackspace.com/archlinux/core/os/x86_64/procps-ng-4.0.4-3-x86_64.pkg.tar.zst)
⬇ retrieved readline.8.2.013-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/readline-8.2.013-1-x86_64.pkg.tar.zst)
⬇ retrieved gcc-libs.14.2.1+r134+gab884fffe3fc-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/gcc-libs-14.2.1+r134+gab884fffe3fc-1-x86_64.pkg.tar.zst)
⬇ retrieved sqlite.3.46.1-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/sqlite-3.46.1-1-x86_64.pkg.tar.zst)
⬇ retrieved systemd-libs.256.6-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/systemd-libs-256.6-1-x86_64.pkg.tar.zst)
⬇ retrieved tzdata.2024b-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/tzdata-2024b-2-x86_64.pkg.tar.zst)
⬇ retrieved util-linux-libs.2.40.2-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/util-linux-libs-2.40.2-1-x86_64.pkg.tar.zst)
⬇ retrieved xz.5.6.3-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/xz-5.6.3-1-x86_64.pkg.tar.zst)
⬇ retrieved vim.9.1.0764-1  (https://mirror.rackspace.com/archlinux/extra/os/x86_64/vim-9.1.0764-1-x86_64.pkg.tar.zst)
⬇ retrieved zlib.1_1.3.1-2  (https://mirror.rackspace.com/archlinux/core/os/x86_64/zlib-1:1.3.1-2-x86_64.pkg.tar.zst)
⬇ retrieved zstd.1.5.6-1  (https://mirror.rackspace.com/archlinux/core/os/x86_64/zstd-1.5.6-1-x86_64.pkg.tar.zst)
⬇ retrieved vim-runtime.9.1.0764-1  (https://mirror.rackspace.com/archlinux/extra/os/x86_64/vim-runtime-9.1.0764-1-x86_64.pkg.tar.zst)
∗ installed tzdata.2024b-2
∗ installed vim-runtime.9.1.0764-1
∗ installed glibc.2.40+r16+gaa533d58ff-2
∗ installed acl.2.3.2-1
∗ installed gcc-libs.14.2.1+r134+gab884fffe3fc-1
∗ installed libcap-ng.0.8.5-2
∗ installed libcap-ng_so.0-64
∗ installed libxcrypt.4.4.36-2
∗ installed libcrypt_so.2-64
∗ installed lmdb.0.9.33-1
∗ installed lz4.1_1.10.0-2
∗ installed ncurses.6.5-3
∗ installed libncursesw_so.6-64
∗ installed openssl.3.3.2-1
∗ installed libcrypto_so.3-64
∗ installed zlib.1_1.3.1-2
∗ installed libevent.2.1.12-4
∗ installed readline.8.2.013-1
∗ installed libreadline_so.8-64
∗ installed libverto.0.3.2-5
∗ installed sqlite.3.46.1-1
∗ installed bash.5.2.037-1
∗ installed libverto-module-base.1
∗ installed libverto_so.1-64
∗ installed sh.1
∗ installed util-linux-libs.2.40.2-1
∗ installed gdbm.1.24-1
∗ installed e2fsprogs.1.47.1-4
∗ installed keyutils.1.6.3-3
∗ installed libcom_err_so.2-64
∗ installed libgdbm_so.6-64
∗ installed libgpg-error.1.50-1
∗ installed libkeyutils_so.1-64
∗ installed libsasl.2.1.28-5
∗ installed libgcrypt.1.11.0-2
∗ installed libldap.2.6.8-2
∗ installed libss_so.2-64
∗ installed xz.5.6.3-1
∗ installed krb5.1.21.3-1
∗ installed libgssapi_krb5_so.2-64
∗ installed libkrb5_so.3-64
∗ installed zstd.1.5.6-1
∗ installed libtirpc.1.3.5-1
∗ installed audit.4.0.2-2
∗ installed libaudit_so.1-64
∗ installed libnsl.2.0.1-1
∗ installed pam.1.6.1-3
∗ installed libcap.2.70-1
∗ installed systemd-libs.256.6-1
∗ installed procps-ng.4.0.4-3
∗ installed gpm.1.20.7.r38.ge82d1a6-6
∗ installed vim.9.1.0764-1
Done.
# Run eval $(opam env) to update the current shell environment
```
