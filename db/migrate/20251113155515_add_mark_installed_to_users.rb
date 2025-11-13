class AddMarkInstalledToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :mark_installed, :boolean, default: false, null: false
  end
end
