class SetUsersFlagsDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :flags, {'HISTORY' => []}
  end
end
