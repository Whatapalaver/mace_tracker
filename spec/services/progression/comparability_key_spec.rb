require "rails_helper"

RSpec.describe Progression::ComparabilityKey do
  describe ".for" do
    it "builds a key from exercise, shape, weight, and work duration for interval_work" do
      session = create(:session, weight_kg: 10, work_seconds: 300)

      expect(described_class.for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        weight: 10.0,
        work_duration: 300
      )
    end

    it "builds a key from exercise, shape, weight, and target_reps for fixed_reps_for_time" do
      session = create(:session, :fixed_reps_for_time, weight_kg: 8, target_reps: 108)

      expect(described_class.for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        weight: 8.0,
        target_reps: 108
      )
    end

    it "builds a key from exercise, shape, weight, and target_reps_per_minute for emom" do
      session = create(:session, :emom, weight_kg: 10, target_reps_per_minute: 20)

      expect(described_class.for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        weight: 10.0,
        target_reps_per_minute: 20
      )
    end

    it "raises for a shape with no defined comparability key" do
      shape = create(:session_shape, name: "unregistered_shape")
      session = create(:session, session_shape: shape)

      expect { described_class.for(session) }.to raise_error(Progression::ComparabilityKey::UnknownShapeError)
    end
  end

  describe ".structural_for" do
    it "returns the same key as .for, without weight" do
      session = create(:session, weight_kg: 10, work_seconds: 300)

      expect(described_class.structural_for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        work_duration: 300
      )
    end

    it "matches across sessions that differ only by weight" do
      lighter = create(:session, weight_kg: 8, work_seconds: 300)
      heavier = create(:session, exercise: lighter.exercise, weight_kg: 10, work_seconds: 300)

      expect(described_class.structural_for(lighter)).to eq(described_class.structural_for(heavier))
    end
  end

  describe ".structural_column_for" do
    it "maps each shape to its structural Session column" do
      expect(described_class.structural_column_for(SessionShape::INTERVAL_WORK)).to eq(:work_seconds)
      expect(described_class.structural_column_for(SessionShape::FIXED_REPS_FOR_TIME)).to eq(:target_reps)
      expect(described_class.structural_column_for(SessionShape::EMOM)).to eq(:target_reps_per_minute)
    end

    it "raises for an unregistered shape" do
      expect { described_class.structural_column_for("unregistered_shape") }.to raise_error(
        Progression::ComparabilityKey::UnknownShapeError
      )
    end
  end
end
