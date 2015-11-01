module Bundle
  class CaskInstaller
    def self.install(name, options = {})
      unless Bundle.brew_installed?
        raise "Unable to install #{name} cask. Homebrew is not currently installed on your system"
      end

      unless Bundle.cask_installed?
        puts "Installing brew cask. It is not currently installed." if ARGV.verbose?
        Bundle.system "brew", "install", "caskroom/cask/brew-cask"

        unless Bundle.cask_installed?
          raise "Unable to install #{name} cask. brew-cask installation failed."
        end
      end

      if installed_casks.include? name
        puts "Skipping install of #{name} cask. It is already installed." if ARGV.verbose?
        return true
      end

      @args = options.fetch(:args, []).map { |k,v| "--#{k}=#{v}" }

      puts "Installing #{name} cask. It is not currently installed." if ARGV.verbose?
      if (success = Bundle.system "brew", "cask", "install", name, *@args)
        installed_casks << name
      end

      success
    end

    def self.installed_casks
      @@installed_casks ||= `brew cask list -1 2>/dev/null`.split("\n").map { |cask| cask.chomp " (!)" }
    end
  end
end
