# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_30_145124) do
  create_table "exercises", force: :cascade do |t|
    t.integer "arm", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["name", "arm", "user_id"], name: "index_exercises_on_name_and_arm_and_user_id", unique: true
    t.index ["user_id"], name: "index_exercises_on_user_id"
  end

  create_table "session_shapes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["name", "user_id"], name: "index_session_shapes_on_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_session_shapes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "benchmark_preset_id"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "exercise_id", null: false
    t.boolean "is_benchmark", default: false, null: false
    t.text "notes"
    t.integer "planned_rest_seconds"
    t.integer "planned_sets"
    t.decimal "planned_weight_kg", precision: 5, scale: 2
    t.integer "planned_work_seconds"
    t.decimal "rpe_session", precision: 3, scale: 1
    t.integer "session_shape_id", null: false
    t.integer "target_reps"
    t.integer "target_reps_per_minute"
    t.datetime "updated_at", null: false
    t.index ["benchmark_preset_id"], name: "index_sessions_on_benchmark_preset_id"
    t.index ["date"], name: "index_sessions_on_date"
    t.index ["exercise_id"], name: "index_sessions_on_exercise_id"
    t.index ["session_shape_id"], name: "index_sessions_on_session_shape_id"
  end

  add_foreign_key "sessions", "exercises"
  add_foreign_key "sessions", "session_shapes"
end
