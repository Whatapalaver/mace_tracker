class CreateBenchmarkPresets < ActiveRecord::Migration[8.1]
  def change
    create_table :benchmark_presets do |t|
      t.string :name, null: false
      t.references :exercise, null: false, foreign_key: true
      t.references :session_shape, null: false, foreign_key: true
      t.decimal :planned_weight_kg, precision: 5, scale: 2
      t.integer :planned_work_seconds
      t.integer :planned_rest_seconds
      t.integer :planned_sets
      t.integer :target_reps
      t.integer :target_reps_per_minute

      t.timestamps
    end
  end
end
