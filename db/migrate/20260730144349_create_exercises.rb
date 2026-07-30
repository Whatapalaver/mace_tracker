class CreateExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :exercises do |t|
      t.string :name, null: false
      t.integer :arm, null: false
      t.text :notes
      t.integer :user_id

      t.timestamps
    end

    add_index :exercises, :user_id
    add_index :exercises, [ :name, :arm, :user_id ], unique: true
  end
end
