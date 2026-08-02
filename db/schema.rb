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

ActiveRecord::Schema[8.1].define(version: 2026_08_02_112253) do
  create_table "benchmark_presets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "exercise_id", null: false
    t.string "name", null: false
    t.integer "reps"
    t.integer "reps_per_minute"
    t.integer "rest_seconds"
    t.integer "session_shape_id", null: false
    t.integer "sets_count"
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 5, scale: 2
    t.integer "work_seconds"
    t.index ["exercise_id"], name: "index_benchmark_presets_on_exercise_id"
    t.index ["session_shape_id"], name: "index_benchmark_presets_on_session_shape_id"
  end

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

  create_table "session_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.integer "heart_rate_avg"
    t.integer "heart_rate_end"
    t.integer "reps"
    t.integer "rest_seconds_actual"
    t.integer "session_id", null: false
    t.integer "set_number", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 5, scale: 2
    t.index ["session_id", "set_number"], name: "index_session_sets_on_session_id_and_set_number", unique: true
    t.index ["session_id"], name: "index_session_sets_on_session_id"
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
    t.integer "reps"
    t.integer "reps_per_minute"
    t.integer "rest_seconds"
    t.decimal "rpe_session", precision: 3, scale: 1
    t.integer "session_shape_id", null: false
    t.integer "sets_count"
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 5, scale: 2
    t.integer "work_seconds"
    t.index ["benchmark_preset_id"], name: "index_sessions_on_benchmark_preset_id"
    t.index ["date"], name: "index_sessions_on_date"
    t.index ["exercise_id"], name: "index_sessions_on_exercise_id"
    t.index ["session_shape_id"], name: "index_sessions_on_session_shape_id"
  end

  create_table "share_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.json "scope", default: {}, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_share_links_on_token", unique: true
  end

  add_foreign_key "benchmark_presets", "exercises"
  add_foreign_key "benchmark_presets", "session_shapes"
  add_foreign_key "session_sets", "sessions"
  add_foreign_key "sessions", "benchmark_presets"
  add_foreign_key "sessions", "exercises"
  add_foreign_key "sessions", "session_shapes"
end
