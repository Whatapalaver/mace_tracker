class AddEquipmentToExercises < ActiveRecord::Migration[8.1]
  def up
    add_reference :exercises, :equipment, foreign_key: true

    equipment_class = Class.new(ActiveRecord::Base) { self.table_name = "equipment" }
    exercise_class = Class.new(ActiveRecord::Base) { self.table_name = "exercises" }

    # Splits every existing "<Equipment> <Movement>" name on its first space (e.g. "Mace 360" ->
    # equipment "Mace", name "360"; "Kettlebell Snatch" -> equipment "Kettlebell", name "Snatch").
    # A name with no space at all (nothing to split) falls back to an "Uncategorized" equipment
    # bucket rather than guessing or leaving equipment_id null, since the column is made NOT NULL
    # below and this must never leave a row unmigrated.
    exercise_class.find_each do |exercise|
      equipment_name, movement_name = exercise.name.split(" ", 2)
      equipment_name, movement_name = "Uncategorized", exercise.name if movement_name.blank?

      equipment = equipment_class.find_or_create_by!(name: equipment_name, user_id: exercise.user_id)
      exercise.update!(name: movement_name, equipment_id: equipment.id)
    end

    change_column_null :exercises, :equipment_id, false

    remove_index :exercises, [ :name, :arm, :user_id ]
    add_index :exercises, [ :equipment_id, :name, :arm, :user_id ], unique: true,
                                                                     name: "index_exercises_on_equipment_name_arm_user"
  end

  def down
    remove_index :exercises, name: "index_exercises_on_equipment_name_arm_user"
    add_index :exercises, [ :name, :arm, :user_id ], unique: true

    exercise_class = Class.new(ActiveRecord::Base) { self.table_name = "exercises" }
    equipment_class = Class.new(ActiveRecord::Base) { self.table_name = "equipment" }
    exercise_class.find_each do |exercise|
      equipment = equipment_class.find(exercise.equipment_id)
      exercise.update!(name: "#{equipment.name} #{exercise.name}")
    end

    remove_reference :exercises, :equipment, foreign_key: true
  end
end
