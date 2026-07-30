class CreateSessionSets < ActiveRecord::Migration[8.1]
  def change
    create_table :session_sets do |t|
      t.references :session, null: false, foreign_key: true
      t.integer :set_number, null: false
      t.integer :reps
      t.decimal :weight_kg, precision: 5, scale: 2
      t.integer :duration_seconds
      t.integer :rest_seconds_actual
      t.integer :heart_rate_avg
      t.integer :heart_rate_end

      t.timestamps
    end

    add_index :session_sets, [ :session_id, :set_number ], unique: true
  end
end
