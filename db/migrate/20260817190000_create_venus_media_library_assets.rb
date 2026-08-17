class CreateVenusMediaLibraryAssets < ActiveRecord::Migration[7.1]
  def change
    create_table :venus_media_library_assets do |t|
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }, index: { unique: true }
      t.references :owner, null: false, polymorphic: true
      t.boolean :community_shared, null: false, default: false
      t.timestamps
    end
  end
end
