module Bundle
  class Dsl
    class Entry
      attr_reader :type, :name, :options

      def initialize(type, name, options = {})
        @type = type
        @name = name
        @options = options
      end
    end

    attr_reader :entries, :cask_arguments

    def initialize(input)
      @input = input
      @entries = []
      @cask_arguments = {}

      @groups = %w[default]

      begin
        process
      # Want to catch all exceptions for e.g. syntax errors.
      rescue Exception => e # rubocop:disable Lint/RescueException
        error_msg = "Invalid Brewfile: #{e.message}"
        raise RuntimeError, error_msg, e.backtrace
      end
    end

    def process
      instance_eval(@input)
    end

    def install
      success = 0
      failure = 0

      without_groups = ARGV.values(:without).to_a
      selected_entries = @entries.select do |entry|
        (without_groups & entry.options[:groups]).empty?
      end

      selected_entries.each do |entry|
        arg = [entry.name]
        verb = "installing"
        cls = case entry.type
        when :brew
          arg << entry.options
          Bundle::BrewInstaller
        when :cask
          arg << entry.options
          Bundle::CaskInstaller
        when :mac_app_store
          arg << entry.options[:id]
          Bundle::MacAppStoreInstaller
        when :tap
          verb = "tapping"
          arg << entry.options[:clone_target]
          Bundle::TapInstaller
        end
        if cls.install(*arg)
          puts "Succeeded in #{verb} #{entry.name}"
          success += 1
        else
          puts "Failed in #{verb} #{entry.name}"
          failure += 1
        end
      end
      puts "\nSuccess: #{success} Fail: #{failure}"

      failure.zero?
    end

    def cask_args(args)
      raise "cask_args(#{args.inspect}) should be a Hash object" unless args.is_a? Hash
      @cask_arguments = args
    end

    def brew(name, options = {})
      raise "name(#{name.inspect}) should be a String object" unless name.is_a? String
      raise "options(#{options.inspect}) should be a Hash object" unless options.is_a? Hash
      name = Bundle::Dsl.sanitize_brew_name(name)
      options[:groups] = @groups.dup
      @entries << Entry.new(:brew, name, options)
    end

    def cask(name, options = {})
      raise "name(#{name.inspect}) should be a String object" unless name.is_a? String
      raise "options(#{options.inspect}) should be a Hash object" unless options.is_a? Hash
      name = Bundle::Dsl.sanitize_cask_name(name)
      options[:args] = @cask_arguments.merge options.fetch(:args, {})
      options[:groups] = @groups.dup
      @entries << Entry.new(:cask, name, options)
    end

    def mas(name, options = {})
      id = options[:id]
      raise "name(#{name.inspect}) should be a String object" unless name.is_a? String
      raise "options[:id](#{id}) should be an Integer object" unless id.is_a? Integer
      options[:groups] = @groups.dup
      @entries << Entry.new(:mac_app_store, name, options)
    end

    def tap(name, clone_target = nil)
      raise "name(#{name.inspect}) should be a String object" unless name.is_a? String
      raise "clone_target(#{clone_target.inspect}) should be nil or a String object" if clone_target && !clone_target.is_a?(String)
      name = Bundle::Dsl.sanitize_tap_name(name)
      options = { clone_target: clone_target, groups: @groups.dup }
      @entries << Entry.new(:tap, name, options)
    end

    def group(name)
      raise "name(#{name.inspect}) should be a String object" unless name.is_a? String
      @groups.push name
      yield
    ensure
      @groups.pop
    end

    HOMEBREW_TAP_ARGS_REGEX = %r{^([\w-]+)/(homebrew-)?([\w-]+)$}
    HOMEBREW_CORE_FORMULA_REGEX = %r{^homebrew/homebrew/([\w+-.]+)$}i
    HOMEBREW_TAP_FORMULA_REGEX = %r{^([\w-]+)/([\w-]+)/([\w+-.]+)$}

    def self.sanitize_brew_name(name)
      name.downcase!
      if name =~ HOMEBREW_CORE_FORMULA_REGEX
        $1
      elsif name =~ HOMEBREW_TAP_FORMULA_REGEX
        user = $1
        repo = $2
        name = $3
        "#{user}/#{repo.sub(/homebrew-/, "")}/#{name}"
      else
        name
      end
    end

    def self.sanitize_tap_name(name)
      name.downcase!
      if name =~ HOMEBREW_TAP_ARGS_REGEX
        "#{$1}/#{$3}"
      else
        name
      end
    end

    def self.sanitize_cask_name(name)
      name.downcase
    end
  end
end
