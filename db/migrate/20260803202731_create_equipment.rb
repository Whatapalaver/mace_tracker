class CreateEquipment < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment do |t|
      t.string :name, null: false
      t.integer :user_id

      t.timestamps
    end

    add_index :equipment, [ :name, :user_id ], unique: true
  end
end
