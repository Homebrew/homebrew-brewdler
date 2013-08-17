module Brewdler
  class RepoInstaller
    def self.install(name)
      if system 'brew tap'
        `brew tap #{name}`
      else
        raise "Unable to tap #{name}. Homebrew is not currently installed on your system"
      end
    end
  end
end
