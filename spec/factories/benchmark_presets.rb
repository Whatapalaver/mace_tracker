FactoryBot.define do
  factory :benchmark_preset do
    sequence(:name) { |n| "Monthly Test #{n}" }
    exercise
    session_shape { SessionShape.find_or_create_by!(name: SessionShape::INTERVAL_WORK, user_id: nil) }
    weight_kg { 10.0 }
    work_seconds { 300 }
    rest_seconds { 600 }
    sets_count { 3 }

    trait :fixed_reps_for_time do
      session_shape { SessionShape.find_or_create_by!(name: SessionShape::FIXED_REPS_FOR_TIME, user_id: nil) }
      work_seconds { nil }
      rest_seconds { nil }
      sets_count { nil }
      target_reps { 100 }
    end

    trait :emom do
      session_shape { SessionShape.find_or_create_by!(name: SessionShape::EMOM, user_id: nil) }
      work_seconds { nil }
      rest_seconds { nil }
      sets_count { nil }
      target_reps_per_minute { 20 }
    end
  end
end
