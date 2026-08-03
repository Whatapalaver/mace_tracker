FactoryBot.define do
  factory :equipment do
    sequence(:name) { |n| "Mace #{n}" }
    user_id { nil }
  end
end
