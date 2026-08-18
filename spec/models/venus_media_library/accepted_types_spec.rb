require "rails_helper"

module VenusMediaLibrary
  RSpec.describe AcceptedTypes do
    it "is empty when parsed from nothing" do
      expect(described_class.parse(nil).any?).to be(false)
      expect(described_class.parse("").any?).to be(false)
    end

    it "splits a comma-separated accept string into tokens" do
      types = described_class.parse("image/png, image/jpeg")

      expect(types.any?).to be(true)
      expect(types.to_input_accept).to eq("image/png,image/jpeg")
    end

    it "matches exact mime types" do
      types = described_class.parse("image/png")

      expect(types.matches?("image/png")).to be(true)
      expect(types.matches?("application/pdf")).to be(false)
      expect(types.matches?(nil)).to be(false)
    end

    it "matches a type wildcard" do
      types = described_class.parse("image/*")

      expect(types.matches?("image/png")).to be(true)
      expect(types.matches?("image/svg+xml")).to be(true)
      expect(types.matches?("application/pdf")).to be(false)
    end

    it "matches file extensions by mapping them to a mime type" do
      types = described_class.parse(".png,.pdf")

      expect(types.matches?("image/png")).to be(true)
      expect(types.matches?("application/pdf")).to be(true)
      expect(types.matches?("image/jpeg")).to be(false)
    end
  end
end
