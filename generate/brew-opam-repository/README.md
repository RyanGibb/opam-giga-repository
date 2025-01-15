# Homebrew opam repository

Experimental opam repository for managing homebrew packages with opam. These packages are create using the `brew opam` command in the branch of homebrew available [here](https://github.com/jonludlam/brew/tree/opam)

To use this, you'll need a patched opam: https://github.com/jonludlam/opam/tree/brew-opam

Also, initialise homebrew with a local clone of the default tap:

```
export HOMEBREW_NO_INSTALL_FROM_API=1
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

or if you've already installed homebrew, 

```
export HOMEBREW_NO_INSTALL_FROM_API=1
brew tap --force homebrew/core
```

There's currently no syncing between brew and opam, so any packages installed with brew itself won't be picked up by opam, though packages installed with opam will be visible by homebrew.

Where there are multiple co-installable versions of a package available in homebrew, these are currently viewed as one opam package, so opam will be unable to install multiple versions.



