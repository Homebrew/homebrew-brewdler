# Homebrew Bundle

Bundler for non-Ruby dependencies from Homebrew, Homebrew Cask, Mac App Store, Whalebrew and Visual Studio Code.

## Requirements

[Homebrew](https://github.com/Homebrew/brew) (on macOS or [Linux](https://docs.brew.sh/Homebrew-on-Linux)) for installing dependencies.

[Homebrew Cask](https://github.com/Homebrew/homebrew-cask) is optional and used for installing Mac applications.

[mas-cli](https://github.com/mas-cli/mas) is optional and used for installing Mac App Store applications.

[Whalebrew](https://github.com/whalebrew/whalebrew) is optional and used for installing Whalebrew images.

[Visual Studio Code](https://code.visualstudio.com/) is optional and used for installing Visual Studio Code extensions.

[VSCodium](https://vscodium.com/) is optional and used for installing VSCodium extensions.

## Installation

`brew bundle` is automatically installed when first run.

## Usage

See [the `brew bundle` section of the `brew generate-man-completions` output](https://docs.brew.sh/Manpage#bundle-subcommand) or `brew bundle --help`.

An example `Brewfile`:

```ruby
# 'brew tap'
tap "homebrew/cask"
# 'brew tap' with custom Git URL
tap "user/tap-repo", "https://user@bitbucket.org/user/homebrew-tap-repo.git"
# 'brew tap' with arguments
tap "user/tap-repo", "https://user@bitbucket.org/user/homebrew-tap-repo.git", force_auto_update: true

# set arguments for all 'brew install --cask' commands
cask_args appdir: "~/Applications", require_sha: true

# 'brew install'
brew "imagemagick"
# 'brew install --with-rmtp', 'brew link --overwrite', 'brew services restart' even if no install/upgrade
brew "denji/nginx/nginx-full", link: :overwrite, args: ["with-rmtp"], restart_service: :always
# 'brew install', always 'brew services restart', 'brew link', 'brew unlink mysql' (if it is installed)
brew "mysql@5.6", restart_service: :changed, link: true, conflicts_with: ["mysql"]
# 'brew install' and run a command if installer or upgraded.
brew "postgresql@16",
     postinstall: "${HOMEBREW_PREFIX}/opt/postgresql@16/bin/postgres -D ${HOMEBREW_PREFIX}/var/postgresql@16"
# install only on specified OS
brew "gnupg" if OS.mac?
brew "glibc" if OS.linux?

# 'brew install --cask'
cask "google-chrome"
# 'brew install --cask --appdir=~/my-apps/Applications'
cask "firefox", args: { appdir: "~/my-apps/Applications" }
# bypass Gatekeeper protections (NOT RECOMMENDED)
cask "firefox", args: { no_quarantine: true }
# always upgrade auto-updated or unversioned cask to latest version even if already installed
cask "opera", greedy: true
# 'brew install --cask' only if '/usr/libexec/java_home --failfast' fails
cask "java" unless system "/usr/libexec/java_home", "--failfast"
# 'brew install --cask' and run a command if installer or upgraded.
cask "google-cloud-sdk", postinstall: "${HOMEBREW_PREFIX}/bin/gcloud components update"

# 'mas install'
mas "1Password", id: 443_987_910

# 'whalebrew install'
whalebrew "whalebrew/wget"

# 'vscode --install-extension'
vscode "GitHub.codespaces"

# 'codium --install-extension'
vscodium "GitHub.codespaces"
```

## Versions and lockfiles

Homebrew is a [rolling release](https://en.wikipedia.org/wiki/Rolling_release) package manager so it does not support installing arbitrary older versions of software.
If your software needs specific pinned versions, consider [`whalebrew`](https://github.com/whalebrew/whalebrew) lines in your `Brewfile` to install [Docker](https://www.docker.com) containers.

## New Installers/Checkers/Dumpers

`brew bundle` currently supports Homebrew, Homebrew Cask, Mac App Store, Whalebrew, Visual Studio Code, and VSCodium.

We are interested in contributions for other installers/checkers/dumpers but they must:

- be able to install software without user interaction
- be able to check if software is installed
- be able to dump the installed software to a format that can be stored in a `Brewfile`
- not require `sudo` to install
- be extremely widely used

Note: based on these criteria, we would not accept e.g. Whalebrew (but have no plans to remove it.)

## Tests

Tests can be run with `bundle install && bundle exec rspec`.
Syntax linting can be run with `brew style homebrew/bundle`.

## Copyright

Copyright (c) Homebrew maintainers and Andrew Nesbitt. See [LICENSE](https://github.com/Homebrew/homebrew-bundle/blob/HEAD/LICENSE) for details.
