FactoryBot.define do
  factory :session_shape do
    sequence(:name) { |n| "shape_#{n}" }
    description { "Some description" }
    user_id { nil }

    trait :interval_work do
      name { "interval_work" }
      description { "Work/rest interval sets" }
    end

    trait :fixed_reps_for_time do
      name { "fixed_reps_for_time" }
      description { "Fixed rep count, timed" }
    end

    trait :emom do
      name { "emom" }
      description { "Every minute on the minute, until failure" }
    end

    trait :sets_and_reps do
      name { "sets_and_reps" }
      description { "Untimed straight sets" }
    end
  end
end
