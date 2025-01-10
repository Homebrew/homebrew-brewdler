# typed: true
# frozen_string_literal: true

require "json"

module Bundle
  module MacAppStoreDumper
    module_function

    def reset!
      @apps = nil
    end

    def apps
      @apps ||= if Bundle.mas_installed?
        `mas list 2>/dev/null`.split("\n").map do |app|
          app_details = app.match(/\A(?<id>\d+)\s+(?<name>.*?)\s+\((?<version>[\d.]*)\)\Z/)

          # Only add the application details should we have a valid match.
          [app_details[:id], app_details[:name]] if app_details
        end
      else
        []
      end.compact
    end

    def app_ids
      apps.map { |id, _| id.to_i }
    end

    def dump
      apps.sort_by { |_, name| name.downcase }.map { |id, name| "mas \"#{name}\", id: #{id}" }.join("\n")
    end
  end
end
