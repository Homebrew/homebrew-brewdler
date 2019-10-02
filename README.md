# Homebrew Bundle

Bundler for non-Ruby dependencies from Homebrew.

[![GitHub Actions](https://github.com/Homebrew/homebrew-bundle/workflows/GitHub%20Actions%20CI/badge.svg)](https://github.com/Homebrew/homebrew-bundle/actions)

## Requirements

[Homebrew](https://github.com/Homebrew/brew) (on macOS or [Linux](https://docs.brew.sh/Homebrew-on-Linux)) for installing the dependencies.

[Homebrew Cask](https://github.com/Homebrew/homebrew-cask) is optional and used for installing Mac applications.

[mas-cli](https://github.com/argon/mas) is optional and used for installing Mac App Store applications.

## Installation

`brew bundle` is automatically installed when run.

## Usage

Create a `Brewfile` in the root of your project with:

```bash
touch Brewfile
```

Add your dependencies in your `Brewfile`:

```ruby
tap "homebrew/cask"
tap "user/tap-repo", "https://user@bitbucket.org/user/homebrew-tap-repo.git"
cask_args appdir: "/Applications"

brew "imagemagick"
brew "denji/nginx/nginx-full", args: ["with-rmtp-module"]
brew "mysql@5.6", restart_service: true, link: true, conflicts_with: ["mysql"]

cask "firefox", args: { appdir: "~/my-apps/Applications" }
cask "google-chrome"
cask "java" unless system "/usr/libexec/java_home --failfast"
cask "homebrew/cask-fonts/font-charter"

mas "1Password", id: 443987910
```

`cask` and `mas` entries are automatically skipped on Linux.
Other entries can be run only on (or not on) Linux with `if OS.mac?` or `if OS.linux?`.

### Install

You can then easily install all of the dependencies with:

```bash
brew bundle
```

If a dependency is already installed and there is an upgrade available it will be upgraded.

`brew bundle` will look for `Brewfile` in the current directory. Use `--file` to specify a path to a different `Brewfile`.

You can skip the installation of dependencies by adding space-separated values to one or more of the following environment variables:

- `HOMEBREW_BUNDLE_BREW_SKIP`
- `HOMEBREW_BUNDLE_CASK_SKIP`
- `HOMEBREW_BUNDLE_MAS_SKIP`
- `HOMEBREW_BUNDLE_TAP_SKIP`

### Dump

You can create a `Brewfile` from all the existing Homebrew packages you have installed with:

```bash
brew bundle dump
```

The `--force` option will allow an existing `Brewfile` to be overwritten as well.
The `--describe` option will output a description comment above each line.
The `--no-restart` option will prevent `restart_service` from being added to ``brew`` lines with running services.

### Cleanup

You can also use `Brewfile` to list the only packages that should be installed, removing any package not present or dependent. This workflow is useful for maintainers or testers who regularly install lots of formulae. To uninstall all Homebrew formulae not listed in `Brewfile`:

```bash
brew bundle cleanup
```

Unless the `--force` option is passed, formulae that would be uninstalled will be listed rather than actually be uninstalled.

### Check

You can check there's anything to install/upgrade in the `Brewfile` by running:

```bash
brew bundle check
```

This provides a successful exit code if everything is up-to-date so is useful for scripting.

For a list of dependencies that are missing, pass `--verbose`. This will also check _all_ dependencies by not exiting on the first missing dependency category.

### List

Outputs a list of all of the entries in the Brewfile.

```bash
brew bundle list
```

Pass one of `--casks`, `--taps`, `--mas`, or `--brews` to limit output to that type. Defaults to `--brews`. Pass `--all` to see everything.

Note that the _type_ of the package is **not** included in this output.

### Exec

Runs an external command within Homebrew's superenv build environment:

```bash
brew bundle exec -- bundle install
```

This sanitized build environment ignores unrequested dependencies, which makes sure that things you didn't specify in your `Brewfile` won't get picked up by commands like `bundle install`, `npm install`, etc. It will also add compiler flags which will help find keg-only dependencies like `openssl`, `icu4c`, etc.

### Restarting services

You can choose whether `brew bundle` restarts a service every time it's run, or
only when the formula is installed or upgraded in your `Brewfile`:

```ruby
# Always restart myservice
brew 'myservice', restart_service: true

# Only restart when installing or upgrading myservice
brew 'myservice', restart_service: :changed
```

## Note

Homebrew does not support installing specific versions of a library, only the most recent one, so there is no good mechanism for storing installed versions in a `.lock` file.

If your software needs specific versions then perhaps you'll want to look at using [Vagrant](https://vagrantup.com/) to better match your development and production environments.

## Tests

Tests can be run with `bundle && bundle exec rake spec`

## Copyright

Copyright (c) Homebrew maintainers and Andrew Nesbitt. See [LICENSE](https://github.com/Homebrew/homebrew-bundle/blob/master/LICENSE) for details.
