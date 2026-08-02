namespace :demo do
  desc "Seed minimal fake sample session history for local development (never runs outside development/test)"
  task seed: [ :environment, "db:seed" ] do
    abort "Refusing to seed demo session data outside development" unless Rails.env.local?

    exercise = Exercise.find_by!(name: "Mace 10-2", arm: "double", user_id: nil)
    interval_work = SessionShape.find_by!(name: SessionShape::INTERVAL_WORK, user_id: nil)
    fixed_reps_for_time = SessionShape.find_by!(name: SessionShape::FIXED_REPS_FOR_TIME, user_id: nil)
    emom = SessionShape.find_by!(name: SessionShape::EMOM, user_id: nil)

    interval_session = Session.find_or_create_by!(exercise: exercise, session_shape: interval_work,
                                                   date: Date.current - 14) do |session|
      session.weight_kg = 10
      session.work_seconds = 300
      session.rest_seconds = 300
      session.sets_count = 3
    end
    [ 20, 19, 18 ].each_with_index do |reps, index|
      interval_session.session_sets.find_or_create_by!(set_number: index + 1) { |set| set.reps = reps }
    end

    fixed_reps_session = Session.find_or_create_by!(exercise: exercise, session_shape: fixed_reps_for_time,
                                                     date: Date.current - 7) do |session|
      session.weight_kg = 8
      session.reps = 108
    end
    fixed_reps_session.session_sets.find_or_create_by!(set_number: 1) do |set|
      set.reps = 108
      set.duration_seconds = 240
    end

    emom_session = Session.find_or_create_by!(exercise: exercise, session_shape: emom, date: Date.current) do |session|
      session.weight_kg = 10
      session.reps_per_minute = 20
    end
    3.times { |index| emom_session.session_sets.find_or_create_by!(set_number: index + 1) }

    puts "Seeded demo sessions: #{Session.count} sessions, #{SessionSet.count} sets."
  end
end
