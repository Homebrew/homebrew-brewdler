# typed: strict
# frozen_string_literal: true

homebrew_version = if HOMEBREW_VERSION.present?
  HOMEBREW_VERSION.delete_prefix(">=")
                  .delete_suffix(" (shallow or no git repository)")
else
  "0.0.1"
end
if Version.new(homebrew_version) < Version.new("4.2.15")
  odie "Your Homebrew is too outdated for `brew bundle`. Please run `brew update`!"
end

require "abstract_command"

module Homebrew
  module Cmd
    class BundleCmd < AbstractCommand
      cmd_args do
        usage_banner <<~EOS
          `bundle` [<subcommand>]

          Bundler for non-Ruby dependencies from Homebrew, Homebrew Cask, Mac App Store, Whalebrew and Visual Studio Code.

          `brew bundle` [`install`]:
          Install and upgrade (by default) all dependencies from the `Brewfile`.

          You can specify the `Brewfile` location using `--file` or by setting the `HOMEBREW_BUNDLE_FILE` environment variable.

          You can skip the installation of dependencies by adding space-separated values to one or more of the following environment variables: `HOMEBREW_BUNDLE_BREW_SKIP`, `HOMEBREW_BUNDLE_CASK_SKIP`, `HOMEBREW_BUNDLE_MAS_SKIP`, `HOMEBREW_BUNDLE_WHALEBREW_SKIP`, `HOMEBREW_BUNDLE_TAP_SKIP`.

          `brew bundle dump`:
          Write all installed casks/formulae/images/taps into a `Brewfile` in the current directory.

          `brew bundle cleanup`:
          Uninstall all dependencies not present in the `Brewfile`.

          This workflow is useful for maintainers or testers who regularly install lots of formulae.

          Unless `--force` is passed, this returns a 1 exit code if anything would be removed.

          `brew bundle check`:
          Check if all dependencies present in the `Brewfile` are installed.

          This provides a successful exit code if everything is up-to-date, making it useful for scripting.

          `brew bundle list`:
          List all dependencies present in the `Brewfile`.

          By default, only Homebrew formula dependencies are listed.

          `brew bundle exec` <command>:
          Run an external command in an isolated build environment based on the `Brewfile` dependencies.

          This sanitized build environment ignores unrequested dependencies, which makes sure that things you didn't specify in your `Brewfile` won't get picked up by commands like `bundle install`, `npm install`, etc. It will also add compiler flags which will help with finding keg-only dependencies like `openssl`, `icu4c`, etc.
        EOS
        flag "--file=",
             description: "Read the `Brewfile` from this location. Use `--file=-` to pipe to stdin/stdout."
        switch "--global",
               description: "Read the `Brewfile` from `~/.Brewfile` or " \
                            "the `HOMEBREW_BUNDLE_FILE_GLOBAL` environment variable, if set."
        switch "-v", "--verbose",
               description: "`install` prints output from commands as they are run. " \
                            "`check` lists all missing dependencies."
        switch "--no-upgrade",
               description: "`install` does not run `brew upgrade` on outdated dependencies. " \
                            "Note they may still be upgraded by `brew install` if needed."
        switch "-f", "--force",
               description: "`install` runs with `--force`/`--overwrite`. " \
                            "`dump` overwrites an existing `Brewfile`. " \
                            "`cleanup` actually performs its cleanup operations."
        switch "--cleanup",
               env:         :bundle_install_cleanup,
               description: "`install` performs cleanup operation, same as running `cleanup --force`. " \
                            "This is enabled by default if `HOMEBREW_BUNDLE_INSTALL_CLEANUP` is set and " \
                            "`--global` is passed."
        switch "--no-lock",
               description: "no-op since `Brewfile.lock.json` was removed.",
               hidden:      true
        switch "--all",
               description: "`list` all dependencies."
        switch "--formula", "--brews",
               description: "`list` or `dump` Homebrew formula dependencies."
        switch "--cask", "--casks",
               description: "`list` or `dump` Homebrew cask dependencies."
        switch "--tap", "--taps",
               description: "`list` or `dump` Homebrew tap dependencies."
        switch "--mas",
               description: "`list` or `dump` Mac App Store dependencies."
        switch "--whalebrew",
               description: "`list` or `dump` Whalebrew dependencies."
        switch "--vscode",
               description: "`list` or `dump` VSCode extensions."
        switch "--no-vscode",
               env:         :bundle_dump_no_vscode,
               description: "`dump` without VSCode extensions. " \
                            "This is enabled by default if `HOMEBREW_BUNDLE_DUMP_NO_VSCODE` is set."
        switch "--vscodium",
              description: "`list` or `dump` VSCodium extensions."
        switch "--no-vscodium",
              env:         :bundle_dump_no_vscodium,
              description: "`dump` without VSCodium extensions. " \
                            "This is enabled by default if `HOMEBREW_BUNDLE_DUMP_NO_VSCODIUM` is set."
        switch "--describe",
               env:         :bundle_dump_describe,
               description: "`dump` adds a description comment above each line, unless the " \
                            "dependency does not have a description. " \
                            "This is enabled by default if `HOMEBREW_BUNDLE_DUMP_DESCRIBE` is set."
        switch "--no-restart",
               description: "`dump` does not add `restart_service` to formula lines."
        switch "--zap",
               description: "`cleanup` casks using the `zap` command instead of `uninstall`."

        conflicts "--all", "--no-vscode"
        conflicts "--all", "--no-vscodium"
        conflicts "--vscode", "--no-vscode"
        conflicts "--vscodium", "--no-vscodium"

        named_args %w[install dump cleanup check exec list]
      end

      sig { override.void }
      def run
        # Keep this inside `run` to keep --help fast.
        require_relative "../lib/bundle"

        subcommand = args.named.first.presence
        if subcommand != "exec" && args.named.size > 1
          raise UsageError, "This command does not take more than 1 subcommand argument."
        end

        global = args.global?
        file = args.file
        args.zap?
        no_upgrade = args.no_upgrade?
        verbose = args.verbose?
        force = args.force?
        zap = args.zap?

        no_type_args = !args.brews? && !args.casks? && !args.taps? && !args.mas? && !args.whalebrew? && !args.vscode? && !args.vscodium?

        case subcommand
        when nil, "install"
          Bundle::Commands::Install.run(
            global:, file:, no_upgrade:, verbose:, force:,
            no_lock:    args.no_lock?,
            quiet:      args.quiet?
          )

          cleanup = if ENV.fetch("HOMEBREW_BUNDLE_INSTALL_CLEANUP", nil)
            args.global?
          else
            args.cleanup?
          end

          if cleanup
            Bundle::Commands::Cleanup.run(
              global:, file:, zap:,
              force:  true,
              dsl:    Bundle::Commands::Install.dsl
            )
          end
        when "dump"
          vscode = if args.no_vscode?
            false
          elsif args.vscode?
            true
          else
            no_type_args
          end

          Bundle::Commands::Dump.run(
            global:, file:, force:,
            describe:   args.describe?,
            no_restart: args.no_restart?,
            taps:       args.taps? || no_type_args,
            brews:      args.brews? || no_type_args,
            casks:      args.casks? || no_type_args,
            mas:        args.mas? || no_type_args,
            whalebrew:  args.whalebrew? || no_type_args,
            vscode:
          )
        when "cleanup"
          Bundle::Commands::Cleanup.run(global:, file:, force:, zap:)
        when "check"
          Bundle::Commands::Check.run(global:, file:, no_upgrade:, verbose:)
        when "exec"
          _subcommand, *named_args = args.named
          Bundle::Commands::Exec.run(*named_args, global:, file:)
        when "list"
          Bundle::Commands::List.run(
            global:,
            file:,
            brews:     args.brews? || args.all? || no_type_args,
            casks:     args.casks? || args.all?,
            taps:      args.taps? || args.all?,
            mas:       args.mas? || args.all?,
            whalebrew: args.whalebrew? || args.all?,
            vscode:    args.vscode? || args.all?,
          )
        else
          raise UsageError, "unknown subcommand: #{subcommand}"
        end
      end
    end
  end
end
