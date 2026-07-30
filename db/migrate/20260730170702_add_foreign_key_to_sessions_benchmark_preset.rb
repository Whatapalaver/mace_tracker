class AddForeignKeyToSessionsBenchmarkPreset < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :sessions, :benchmark_presets
  end
end
