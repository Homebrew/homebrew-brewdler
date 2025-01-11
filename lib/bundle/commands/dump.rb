# frozen_string_literal: true

module Bundle
  module Commands
    module Dump
      module_function

      def run(global:, file:, describe:, force:, no_restart:, taps:, brews:, casks:, mas:, whalebrew:, vscode:, vscodium:)
        Bundle::Dumper.dump_brewfile(
          global:, file:, describe:, force:, no_restart:, taps:, brews:, casks:, mas:, whalebrew:, vscode:, vscodium:,
        )
      end
    end
  end
end
