FactoryBot.define do
  factory :exercise do
    sequence(:name) { |n| "Mace 360 #{n}" }
    arm { :double }
    notes { "Some notes" }
    user_id { nil }
  end
end
