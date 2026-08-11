FactoryBot.define do
  factory :tool do
    association :equipment
    sequence(:name) { |n| "Tool #{n}" }
    notes { "Some notes" }
    user_id { nil }
  end
end
