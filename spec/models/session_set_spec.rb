require "rails_helper"

RSpec.describe SessionSet, type: :model do
  it "has a valid factory" do
    expect(build(:session_set)).to be_valid
  end

  describe "validations" do
    it { is_expected.to belong_to(:session) }
    it { is_expected.to validate_presence_of(:set_number) }

    it "requires set_number to be unique within the same session" do
      session = create(:session)
      create(:session_set, session: session, set_number: 1)
      duplicate = build(:session_set, session: session, set_number: 1)

      expect(duplicate).not_to be_valid
    end

    it "allows the same set_number across different sessions" do
      create(:session_set, set_number: 1)
      other_session_set = build(:session_set, set_number: 1)

      expect(other_session_set).to be_valid
    end

    it "rejects a non-positive set_number" do
      expect(build(:session_set, set_number: 0)).not_to be_valid
    end

    it "rejects a non-positive reps" do
      expect(build(:session_set, reps: 0)).not_to be_valid
    end

    it "allows reps to be nil" do
      expect(build(:session_set, reps: nil)).to be_valid
    end

    it "allows rest_seconds_actual to be 0 (a single-set all-out effort)" do
      expect(build(:session_set, rest_seconds_actual: 0)).to be_valid
    end

    it "rejects a negative rest_seconds_actual" do
      expect(build(:session_set, rest_seconds_actual: -1)).not_to be_valid
    end
  end

  describe "#effective_weight_kg" do
    it "returns its own weight_kg override when present" do
      session = create(:session, planned_weight_kg: 10.0)
      session_set = build(:session_set, session: session, weight_kg: 12.5)

      expect(session_set.effective_weight_kg).to eq(12.5)
    end

    it "falls back to the session's planned_weight_kg when not overridden" do
      session = create(:session, planned_weight_kg: 10.0)
      session_set = build(:session_set, session: session, weight_kg: nil)

      expect(session_set.effective_weight_kg).to eq(10.0)
    end
  end
end
