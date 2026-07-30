FactoryBot.define do
  factory :benchmark_preset do
    sequence(:name) { |n| "Monthly Test #{n}" }
    exercise
    session_shape { SessionShape.find_or_create_by!(name: SessionShape::INTERVAL_WORK, user_id: nil) }
    planned_weight_kg { 10.0 }
    planned_work_seconds { 300 }
    planned_rest_seconds { 600 }
    planned_sets { 3 }

    trait :fixed_reps_for_time do
      session_shape { SessionShape.find_or_create_by!(name: SessionShape::FIXED_REPS_FOR_TIME, user_id: nil) }
      planned_work_seconds { nil }
      planned_rest_seconds { nil }
      planned_sets { nil }
      target_reps { 100 }
    end

    trait :emom do
      session_shape { SessionShape.find_or_create_by!(name: SessionShape::EMOM, user_id: nil) }
      planned_work_seconds { nil }
      planned_rest_seconds { nil }
      planned_sets { nil }
      target_reps_per_minute { 20 }
    end
  end
end
