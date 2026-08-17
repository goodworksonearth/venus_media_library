module VenusMediaLibrary
  class Asset < ApplicationRecord
    attribute :community_shared, :boolean, default: false

    belongs_to :blob, class_name: "ActiveStorage::Blob"
    belongs_to :owner, polymorphic: true

    validates :blob, uniqueness: true
  end
end
