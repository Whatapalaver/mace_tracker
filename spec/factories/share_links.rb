FactoryBot.define do
  factory :share_link do
    scope { {} }
    expires_at { nil }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :scoped_to_exercise do
      transient do
        exercise { create(:exercise) }
      end

      scope { { "exercise_id" => exercise.id } }
    end
  end
end
