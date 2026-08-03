FactoryBot.define do
  factory :exercise do
    association :equipment
    sequence(:name) { |n| "360 #{n}" }
    arm { :double }
    notes { "Some notes" }
    user_id { nil }
  end
end
