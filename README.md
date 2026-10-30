# dotfiles

Personal dotfiles for dev containers. VS Code and the devcontainer CLI clone
this repo into new containers and run `install.sh`, which:

- installs `zsh` (plus `git` and `curl` if missing) with apt, when it can run as root or with passwordless sudo
- installs [Oh My Zsh](https://ohmyz.sh) unattended, keeping any existing `~/.zshrc`
- sets the theme to `agnoster` (needs a Powerline-patched font, such as a Nerd Font, in the host terminal)
- makes zsh the login shell, or, without root, has interactive bash hand over to zsh

It is safe to re-run. If zsh is missing and the container user has no root or
sudo, it skips the setup; add `zsh` to the image instead.

## Using it

VS Code user settings:

```json
"dotfiles.repository": "WalkingDisaster/dotfiles",
"dotfiles.targetPath": "~/dotfiles",
"dotfiles.installCommand": "install.sh"
```
