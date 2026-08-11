class CreateTools < ActiveRecord::Migration[8.1]
  def change
    create_table :tools do |t|
      t.string :name, null: false
      t.references :equipment, null: false, foreign_key: true
      t.text :notes
      t.integer :user_id

      t.timestamps
    end

    add_index :tools, [ :equipment_id, :name, :user_id ], unique: true

    add_reference :sessions, :tool, foreign_key: true
  end
end
