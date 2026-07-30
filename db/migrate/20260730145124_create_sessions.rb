class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.date :date, null: false
      t.references :exercise, null: false, foreign_key: true
      t.references :session_shape, null: false, foreign_key: true
      t.integer :benchmark_preset_id
      t.boolean :is_benchmark, null: false, default: false
      t.decimal :planned_weight_kg, precision: 5, scale: 2
      t.integer :planned_work_seconds
      t.integer :planned_rest_seconds
      t.integer :planned_sets
      t.integer :target_reps
      t.integer :target_reps_per_minute
      t.decimal :rpe_session, precision: 3, scale: 1
      t.text :notes

      t.timestamps
    end

    add_index :sessions, :benchmark_preset_id
    add_index :sessions, :date
  end
end
