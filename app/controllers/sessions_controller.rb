class SessionsController < ApplicationController
  def new
    @session = Session.new(date: Date.current)
    @exercises = Exercise.order(:name)
    @session_shapes = session_shapes
  end

  def create
    @session = Session.new(session_params)

    if @session.save
      redirect_to @session, notice: "Session logged."
    else
      @exercises = Exercise.order(:name)
      @session_shapes = session_shapes
      render :new, status: :unprocessable_content
    end
  end

  def show
    @session = Session.find(params[:id])
    @calculator = Progression::Calculator.for(@session)
    @pace_series = interval_work? ? Progression::IntervalWorkPaceSeries.new(@session).to_h : nil
  end

  private

  def interval_work?
    @session.session_shape.name == SessionShape::INTERVAL_WORK
  end

  def session_shapes
    SessionShape::ORDERED_NAMES.each { |name| SessionShape.find_or_create_by!(name: name, user_id: nil) }
    SessionShape.global_ordered
  end

  def session_params
    params.expect(session: [ :date, :exercise_id, :session_shape_id, :planned_weight_kg,
                             :planned_work_seconds, :planned_rest_seconds, :planned_sets,
                             :target_reps, :target_reps_per_minute, :notes ])
  end
end
