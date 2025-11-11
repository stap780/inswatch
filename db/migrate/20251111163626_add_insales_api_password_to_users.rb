class AddInsalesApiPasswordToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :insales_api_password, :string
  end
end
