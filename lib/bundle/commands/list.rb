# frozen_string_literal: true

module Bundle
  module Commands
    module List
      module_function

      def run(global:, file:, brews:, casks:, taps:, mas:, whalebrew:, vscode:, vscodium:)
        parsed_entries = Brewfile.read(global:, file:).entries
        Bundle::Lister.list(
          parsed_entries,
          brews:, casks:, taps:, mas:, whalebrew:, vscode:, vscodium:,
        )
      end
    end
  end
end
