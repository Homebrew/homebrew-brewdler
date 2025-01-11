# frozen_string_literal: true

module Bundle
  module Checker
    class VscodiumExtensionChecker < Bundle::Checker::Base
      PACKAGE_TYPE = :vscodium
      PACKAGE_TYPE_NAME = "VSCodium Extension"

      def failure_reason(extension, no_upgrade:)
        "#{PACKAGE_TYPE_NAME} #{extension} needs to be installed."
      end

      def installed_and_up_to_date?(extension, no_upgrade: false)
        Bundle::VscodiumExtensionInstaller.extension_installed?(extension)
      end
    end
  end
end
