# frozen_string_literal: true

module Bundle
  module VscodiumExtensionDumper
    module_function

    def reset!
      @extensions = nil
    end

    def extensions
      @extensions ||= if Bundle.vscodium_installed?
        Bundle.exchange_uid_if_needed! do
          `codium --list-extensions 2>/dev/null`
        end.split("\n").map(&:downcase)
      else
        []
      end
    end

    def dump
      extensions.map { |name| "vscodium \"#{name}\"" }.join("\n")
    end
  end
end
