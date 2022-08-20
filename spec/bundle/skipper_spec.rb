# frozen_string_literal: true

require "spec_helper"

describe Bundle::Skipper do
  subject(:skipper) { described_class }

  before do
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with("HOMEBREW_BUNDLE_BREW_SKIP").and_return("mysql")
    allow(ENV).to receive(:[]).with("HOMEBREW_BUNDLE_WHALEBREW_SKIP").and_return("whalebrew/imagemagick")
    allow(ENV).to receive(:[]).with("HOMEBREW_BUNDLE_TAP_SKIP").and_return("org/repo")
    allow(Formatter).to receive(:warning)
    skipper.instance_variable_set(:@skipped_entries, nil)
    skipper.instance_variable_set(:@failed_taps, nil)
  end

  describe ".skip?" do
    context "with a listed formula" do
      let(:entry) { Bundle::Dsl::Entry.new(:brew, "mysql") }

      it "returns true" do
        expect(skipper.skip?(entry)).to be true
      end
    end

    context "with an unbottled formula on ARM", :needs_macos do
      let(:entry) { Bundle::Dsl::Entry.new(:brew, "mysql") }

      it "returns true" do
        allow(Hardware::CPU).to receive(:arm?).and_return(true)
        allow_any_instance_of(Formula).to receive(:bottled?).and_return(false)

        expect(skipper.skip?(entry)).to be true
      end
      it "returns false when HOMEBREW_INSTALL_IF_BOTTLE_MISSING is true" do
        allow(ENV).to receive(:[]).with("HOMEBREW_INSTALL_IF_BOTTLE_MISSING").and_return("true")
        allow(Hardware::CPU).to receive(:arm?).and_return(true)
        allow_any_instance_of(Formula).to receive(:bottled?).and_return(false)

        expect(skipper.skip?(entry)).to be false 
      end

    end

    context "with an unlisted cask", :needs_macos do
      let(:entry) { Bundle::Dsl::Entry.new(:cask, "java") }

      it "returns false" do
        expect(skipper.skip?(entry)).to be false
      end
    end

    context "with a listed whalebrew image" do
      let(:entry) { Bundle::Dsl::Entry.new(:whalebrew, "whalebrew/imagemagick") }

      it "returns true" do
        expect(skipper.skip?(entry)).to be true
      end
    end

    context "with a listed formula in a failed tap" do
      let(:entry) { Bundle::Dsl::Entry.new(:brew, "org/repo/formula") }

      it "returns true" do
        skipper.tap_failed!("org/repo")

        expect(skipper.skip?(entry)).to be true
      end
    end
  end

  describe ".failed_tap!" do
    context "with a tap" do
      let(:tap) { Bundle::Dsl::Entry.new(:tap, "org/repo-b") }
      let(:entry) { Bundle::Dsl::Entry.new(:brew, "org/repo-b/formula") }

      it "returns false" do
        expect(skipper.skip?(entry)).to be false

        skipper.tap_failed! tap.name

        expect(skipper.skip?(entry)).to be true
      end
    end
  end
end
