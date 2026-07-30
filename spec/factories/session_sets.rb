FactoryBot.define do
  factory :session_set do
    session
    sequence(:set_number)
    reps { 20 }
    weight_kg { nil }
    duration_seconds { 60 }
    rest_seconds_actual { 60 }
    heart_rate_avg { nil }
    heart_rate_end { nil }
  end
end
