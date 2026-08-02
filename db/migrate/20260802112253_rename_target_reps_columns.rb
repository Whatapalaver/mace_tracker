class RenameTargetRepsColumns < ActiveRecord::Migration[8.1]
  def change
    %i[sessions benchmark_presets].each do |table|
      rename_column table, :target_reps, :reps
      rename_column table, :target_reps_per_minute, :reps_per_minute
    end
  end
end
