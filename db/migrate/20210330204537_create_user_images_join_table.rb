class CreateUserImagesJoinTable < ActiveRecord::Migration[6.1]
  def change
    create_join_table :users, :stored_images, table_name: :user_images
  end
end
