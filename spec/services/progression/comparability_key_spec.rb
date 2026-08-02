require "rails_helper"

RSpec.describe Progression::ComparabilityKey do
  describe ".for" do
    it "builds a key from exercise, shape, weight, work duration, rest duration, and sets count for interval_work" do
      session = create(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 300, sets_count: 5)

      expect(described_class.for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        weight: 10.0,
        work_duration: 300,
        rest_duration: 300,
        sets_count: 5
      )
    end

    it "builds a key from exercise, shape, weight, and reps for fixed_reps_for_time" do
      session = create(:session, :fixed_reps_for_time, weight_kg: 8, reps: 108)

      expect(described_class.for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        weight: 8.0,
        reps: 108
      )
    end

    it "builds a key from exercise, shape, weight, and reps_per_minute for emom" do
      session = create(:session, :emom, weight_kg: 10, reps_per_minute: 20)

      expect(described_class.for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        weight: 10.0,
        reps_per_minute: 20
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
      session = create(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 300, sets_count: 5)

      expect(described_class.structural_for(session)).to eq(
        exercise_id: session.exercise_id,
        session_shape_id: session.session_shape_id,
        work_duration: 300,
        rest_duration: 300,
        sets_count: 5
      )
    end

    it "matches across sessions that differ only by weight" do
      lighter = create(:session, weight_kg: 8, work_seconds: 300, rest_seconds: 300, sets_count: 5)
      heavier = create(:session, exercise: lighter.exercise, weight_kg: 10, work_seconds: 300,
                                  rest_seconds: 300, sets_count: 5)

      expect(described_class.structural_for(lighter)).to eq(described_class.structural_for(heavier))
    end

    it "differs when sessions share work duration but differ in rest or set count" do
      single_set_no_rest = create(:session, weight_kg: 10, work_seconds: 300, rest_seconds: 0, sets_count: 1)
      three_sets_with_rest = create(:session, exercise: single_set_no_rest.exercise, weight_kg: 10,
                                               work_seconds: 300, rest_seconds: 300, sets_count: 3)

      expect(described_class.structural_for(single_set_no_rest))
        .not_to eq(described_class.structural_for(three_sets_with_rest))
    end
  end

  describe ".structural_columns_for" do
    it "maps interval_work to work duration, rest duration, and sets count by default (full granularity)" do
      expect(described_class.structural_columns_for(SessionShape::INTERVAL_WORK)).to eq(
        [ :work_seconds, :rest_seconds, :sets_count ]
      )
    end

    it "maps interval_work to work duration alone under segment granularity" do
      expect(described_class.structural_columns_for(SessionShape::INTERVAL_WORK, granularity: "segment"))
        .to eq([ :work_seconds ])
    end

    it "ignores granularity for fixed_reps_for_time and emom, which have no wrapping structure to drop" do
      expect(described_class.structural_columns_for(SessionShape::FIXED_REPS_FOR_TIME, granularity: "segment"))
        .to eq([ :reps ])
      expect(described_class.structural_columns_for(SessionShape::EMOM, granularity: "segment"))
        .to eq([ :reps_per_minute ])
    end

    it "raises for an unregistered shape" do
      expect { described_class.structural_columns_for("unregistered_shape") }.to raise_error(
        Progression::ComparabilityKey::UnknownShapeError
      )
    end
  end

  describe ".decode_structural_value" do
    it "decodes a full-granularity interval_work value into all three columns" do
      expect(described_class.decode_structural_value(SessionShape::INTERVAL_WORK, "300:300:3")).to eq(
        work_seconds: 300, rest_seconds: 300, sets_count: 3
      )
    end

    it "decodes a segment-granularity interval_work value into just work_seconds" do
      expect(described_class.decode_structural_value(SessionShape::INTERVAL_WORK, "300", granularity: "segment"))
        .to eq(work_seconds: 300)
    end
  end
end
