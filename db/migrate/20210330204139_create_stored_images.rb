class CreateStoredImages < ActiveRecord::Migration[6.1]
  def change
    create_table :stored_images do |t|
      t.string :url

      t.timestamps
    end
  end
end
