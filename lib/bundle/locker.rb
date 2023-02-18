# frozen_string_literal: true

require "tap"
require "os"
require "development_tools"
require "env_config"

module Bundle
  module Locker
    module_function

    def lockfile(global: false, file: nil)
      brew_file_path = Brewfile.path(global: global, file: file)
      lock_file_path = brew_file_path.dirname/"#{brew_file_path.basename}.lock.json"

      # no need to call realpath if the lockfile is not a symlink
      # unnecessary call to fs, also breaks tests, which use filenames that are not in fs
      lock_file_path = lock_file_path.realpath if lock_file_path.symlink?

      lock_file_path
    end

    def write_lockfile?(global: false, file: nil, no_lock: false)
      return false if no_lock
      return false if ENV["HOMEBREW_BUNDLE_NO_LOCK"]

      # handle the /dev/stdin and /dev/stdout cases
      return false if lockfile(global: global, file: file).parent.to_s == "/dev"

      true
    end

    def lock(entries, global: false, file: nil, no_lock: false)
      return false unless write_lockfile?(global: global, file: file, no_lock: no_lock)

      lockfile = lockfile(global: global, file: file)

      lock = JSON.parse(lockfile.read) if lockfile.exist?
      lock ||= {}
      lock["version"] = "1"
      lock["entries"] ||= {}
      lock["system"] ||= {}

      entries.each do |entry|
        next if Bundle::Skipper.skip?(entry, silent: true)

        entry_type_key = entry.type.to_s
        options = entry.options
        lock["entries"][entry_type_key] ||= {}
        lock["entries"][entry_type_key][entry.name] = case entry.type
        when :brew
          brew_list(entry.name)
        when :cask
          options.delete(:args) if options[:args].blank?
          { version: cask_list[entry.name] }
        when :mas
          options.delete(:id)
          mas_list[entry.name]
        when :whalebrew
          whalebrew_list[entry.name]
        when :tap
          options.delete(:clone_target) if options[:clone_target].blank?
          options.delete(:pin) if options[:pin] == false
          { revision: Tap.fetch(entry.name).git_head }
        end

        next if options.blank?

        lock["entries"][entry_type_key][entry.name] ||= {}
        lock["entries"][entry_type_key][entry.name]["options"] =
          options.deep_stringify_keys
      end

      if OS.mac?
        lock["system"]["macos"] ||= {}
        version, hash = system_macos
        lock["system"]["macos"][version] = hash
      elsif OS.linux?
        lock["system"]["linux"] ||= {}
        version, hash = system_linux
        lock["system"]["linux"][version] = hash
      end

      json = JSON.pretty_generate(lock)
      begin
        lockfile.unlink if lockfile.exist?
        lockfile.write("#{json}\n")
      rescue Errno::EPERM, Errno::EACCES, Errno::ENOTEMPTY
        opoo "Could not write to #{lockfile}!"
        return false
      end

      true
    end

    def brew_list(name)
      @brew_list ||= begin
        # reset and reget all versions from scratch
        Bundle::BrewDumper.reset!
        {}
      end

      return @brew_list[name] if @brew_list.key?(name)

      @brew_list[name] ||= Bundle::BrewDumper.formulae_by_name(name)
                                            &.slice(:version, :bottle)
    end

    def cask_list
      return {} unless OS.mac?

      @cask_list ||= begin
        # reset and reget all versions from scratch
        Bundle::CaskDumper.reset!
        Bundle::CaskDumper.cask_versions
      end
    end

    def mas_list
      return {} unless OS.mac?

      @mas_list ||= `mas list`.lines
                              .each_with_object({}) do |line, name_id_versions|
        line = line.split
        id = line.shift
        version = line.pop.delete("()")
        name = line.join(" ")
        name_id_versions[name] = {
          id:      id,
          version: version,
        }
      end
    end

    def whalebrew_list
      @whalebrew_list ||= Bundle::WhalebrewDumper.images.each_with_object({}) do |image, name_versions|
        _, version = `docker image inspect #{image} --format '{{ index .RepoDigests 0 }}'`.split(":")
        name_versions[image] = version.chomp
      end
    end

    def system_macos
      [MacOS.version.to_sym.to_s, {
        "HOMEBREW_VERSION"       => HOMEBREW_VERSION,
        "HOMEBREW_PREFIX"        => HOMEBREW_PREFIX.to_s,
        "Homebrew/homebrew-core" => Homebrew::EnvConfig.install_from_api? ? "api" : CoreTap.instance.git_head,
        "CLT"                    => MacOS::CLT.version.to_s,
        "Xcode"                  => MacOS::Xcode.version.to_s,
        "macOS"                  => MacOS.full_version.to_s,
      }]
    end

    def system_linux
      # TODO: remove once https://github.com/Homebrew/brew/pull/13577 is merged and tagged.
      gcc_version = if DevelopmentTools.respond_to?(:gcc_version)
        DevelopmentTools.gcc_version("gcc")
      else
        DevelopmentTools.non_apple_gcc_version("gcc")
      end

      [OS::Linux.os_version, {
        "HOMEBREW_VERSION"        => HOMEBREW_VERSION,
        "HOMEBREW_PREFIX"         => HOMEBREW_PREFIX.to_s,
        "Homebrew/linuxbrew-core" => Homebrew::EnvConfig.install_from_api? ? "api" : CoreTap.instance.git_head,
        "GCC"                     => gcc_version,
      }]
    end
  end
end
