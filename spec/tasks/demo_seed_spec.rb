require "rails_helper"

RSpec.describe "demo:seed rake task" do
  def run_task
    Rake::Task["demo:seed"].reenable
    Rake::Task["db:seed"].reenable
    Rake::Task["demo:seed"].invoke
  end

  it "creates one session per shape, each with sets, against the seeded Mace 10-2 exercise" do
    expect { run_task }.to change(Session, :count).by(3)

    exercise = Exercise.find_by!(name: "Mace 10-2", arm: "double", user_id: nil)
    sessions = Session.where(exercise: exercise).includes(:session_shape, :session_sets)

    expect(sessions.map { |s| s.session_shape.name }).to contain_exactly(
      "interval_work", "fixed_reps_for_time", "emom"
    )
    expect(sessions.flat_map(&:session_sets)).not_to be_empty
  end

  it "is idempotent when run more than once" do
    run_task

    expect { run_task }.not_to change(Session, :count)
    expect { run_task }.not_to change(SessionSet, :count)
  end
end
