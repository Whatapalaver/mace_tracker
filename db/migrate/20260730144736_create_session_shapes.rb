class CreateSessionShapes < ActiveRecord::Migration[8.1]
  def change
    create_table :session_shapes do |t|
      t.string :name, null: false
      t.text :description
      t.integer :user_id

      t.timestamps
    end

    add_index :session_shapes, :user_id
    add_index :session_shapes, [ :name, :user_id ], unique: true
  end
end
