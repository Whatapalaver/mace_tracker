class RenamePlannedColumnsToDropPlannedPrefix < ActiveRecord::Migration[8.1]
  def change
    %i[sessions benchmark_presets].each do |table|
      rename_column table, :planned_weight_kg, :weight_kg
      rename_column table, :planned_work_seconds, :work_seconds
      rename_column table, :planned_rest_seconds, :rest_seconds
      rename_column table, :planned_sets, :sets_count
    end
  end
end
