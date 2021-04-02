class AddFlagsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :flags, :json
  end
end
