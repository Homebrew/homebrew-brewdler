# frozen_string_literal: true

module Bundle
  module VscodiumExtensionInstaller
    module_function

    def reset!
      @installed_extensions = nil
    end

    def preinstall(name, no_upgrade: false, verbose: false)
      if !Bundle.vscodium_installed? && Bundle.cask_installed?
        puts "Installing vscodium. It is not currently installed." if verbose
        Bundle.system HOMEBREW_BREW_FILE, "install", "--cask", "vscodium", verbose:
      end

      if extension_installed?(name)
        puts "Skipping install of #{name} VSCodium extension. It is already installed." if verbose
        return false
      end

      raise "Unable to install #{name} VSCodium extension. VSCodium is not installed." unless Bundle.vscodium_installed?

      true
    end

    def install(name, preinstall: true, no_upgrade: false, verbose: false, force: false)
      return true unless preinstall
      return true if extension_installed?(name)

      puts "Installing #{name} VSCodium extension. It is not currently installed." if verbose

      return false unless Bundle.exchange_uid_if_needed! do
        Bundle.system("codium", "--install-extension", name, verbose:)
      end

      installed_extensions << name

      true
    end

    def extension_installed?(name)
      installed_extensions.include? name.downcase
    end

    def installed_extensions
      @installed_extensions ||= Bundle::VscodiumExtensionDumper.extensions
    end
  end
end
