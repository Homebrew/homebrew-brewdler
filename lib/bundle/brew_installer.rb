module Bundle
  class BrewInstaller
    def self.install(name, options = {})
      new(name, options).install_or_upgrade
    end

    def initialize(name, options = {})
      if Bundle.brew_installed?
        @name = name
        @args = prepare_args(options[:args])
      else
        raise "Unable to install #{name}. Homebrew is not currently installed on your system"
      end
    end

    def install_or_upgrade
      if installed?
        upgrade!
      else
        install!
      end
    end

    private

    def installed_formulae
      @@installed_formulae ||= `brew list -1`.split("\n")
    end

    def outdated_formulae
      @@outdated_formulae ||= `brew outdated --quiet`.split("\n")
    end

    def pinned_formulae
      @@pinned_formulae ||= `brew list --pinned`.split("\n")
    end

    def installed?
      installed_formulae.include?(@name)
    end

    def upgradable?
      outdated_formulae.include?(@name) &&
        ! pinned_formulae.include?(@name)
    end

    def install!
      if (success = Bundle.system("brew", "install", @name, *@args))
        installed_formulae << @name
      end

      success
    end

    def upgrade!
      return Bundle.system("brew", "upgrade", @name) if !install_only? && upgradable?
      true
    end

    def install_only?
      ARGV.include?("--install-only")
    end

    def prepare_args(args)
      args ||= []
      args.map { |arg| "--#{arg}" }
    end
  end
end
