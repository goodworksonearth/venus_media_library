# frozen_string_literal: true

require "rails_helper"

RSpec.describe VenusMediaLibrary::Configuration do
  describe "DEFAULT_ADMIN predicate" do
    it "uses the admin? convention when the user responds to it" do
      expect(described_class::DEFAULT_ADMIN.call(double(admin?: true))).to be(true)
      expect(described_class::DEFAULT_ADMIN.call(double(admin?: false))).to be(false)
    end

    it "falls back to the is_admin? convention" do
      user = Class.new { def is_admin? = true }.new
      expect(described_class::DEFAULT_ADMIN.call(user)).to be(true)
    end

    it "is false for nil or a user with neither predicate" do
      expect(described_class::DEFAULT_ADMIN.call(nil)).to be(false)
      expect(described_class::DEFAULT_ADMIN.call(Object.new)).to be(false)
    end

    it "is the out-of-the-box default admin predicate" do
      expect(described_class.new.admin).to eq(described_class::DEFAULT_ADMIN)
    end
  end
end
