class AddInsalesFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :insales_id, :string
    add_column :users, :shop, :string
    add_column :users, :installed, :boolean, default: false, null: false
    add_column :users, :last_login_at, :datetime
    
    # Billing fields
    add_column :users, :insales_charge_id, :integer
    add_column :users, :charge_status, :string
    add_column :users, :monthly, :decimal, precision: 10, scale: 2
    add_column :users, :trial_ends_at, :date
    add_column :users, :paid_till, :date
    add_column :users, :blocked, :boolean
    
    # Indexes
    add_index :users, :insales_id, unique: true
    add_index :users, :shop
    add_index :users, :insales_charge_id
  end
end
