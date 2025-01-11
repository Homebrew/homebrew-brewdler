# frozen_string_literal: true

module Bundle
  module Lister
    module_function

    def list(entries, brews:, casks:, taps:, mas:, whalebrew:, vscode:, vscodium:)
      entries.each do |entry|
        puts entry.name if show?(entry.type, brews:, casks:, taps:, mas:, whalebrew:, vscode:, vscodium:)
      end
    end

    def self.show?(type, brews:, casks:, taps:, mas:, whalebrew:, vscode:, vscodium:)
      return true if brews && type == :brew
      return true if casks && type == :cask
      return true if taps && type == :tap
      return true if mas && type == :mas
      return true if whalebrew && type == :whalebrew
      return true if vscode && type == :vscode
      return true if vscodium && type == :vscodium

      false
    end
  end
end
