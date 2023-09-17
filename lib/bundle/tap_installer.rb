# frozen_string_literal: true

module Bundle
  module TapInstaller
    module_function

    def preinstall(name, verbose: false, **_options)
      if installed_taps.include? name
        ohai "Skipping install of #{name} tap. It is already installed." if verbose
        return false
      end

      true
    end

    def install(name, preinstall: true, verbose: false, **options)
      return true unless preinstall

      ohai "Installing #{name} tap. It is not currently installed." if verbose
      args = []
      args.append("--force-auto-update") if options[:force_auto_update]

      success = if options[:clone_target]
        Bundle.system HOMEBREW_BREW_FILE, "tap", name, options[:clone_target], *args, verbose: verbose
      else
        Bundle.system HOMEBREW_BREW_FILE, "tap", name, *args, verbose: verbose
      end

      unless success
        Bundle::Skipper.tap_failed!(name)
        return false
      end

      installed_taps << name
      true
    end

    def installed_taps
      @installed_taps ||= Bundle::TapDumper.tap_names
    end
  end
end
