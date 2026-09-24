# Ward (ward.deltavdevs.com) is the DeltaVDevs account. Users sign in with it and
# are keyed on its stable `sub`; Google/GitHub/email stay for existing accounts.
class AddWardToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ward_sub, :string
    add_column :users, :ward_name, :string
    add_column :users, :ward_avatar_url, :string
    add_index :users, :ward_sub, unique: true
  end
end
