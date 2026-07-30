class CreateShareLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :share_links do |t|
      t.string :token, null: false
      t.json :scope, null: false, default: {}
      t.datetime :expires_at

      t.timestamps
    end

    add_index :share_links, :token, unique: true
  end
end
