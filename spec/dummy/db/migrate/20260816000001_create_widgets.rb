# Test-only model for the dummy app: gives the gem's attach-mode specs a record
# with `has_one_attached :cover` to attach a picked blob's signed_id to.
class CreateWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :widgets do |t|
      t.string :name
      t.timestamps
    end
  end
end
