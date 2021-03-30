class AddVerifiedToStoredImages < ActiveRecord::Migration[6.1]
  def change
    add_column :stored_images, :verified, :boolean, default: false, null: false
  end
end
