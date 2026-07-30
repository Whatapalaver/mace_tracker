class SessionsController < ApplicationController
  def new
    @session = Session.new(date: Date.current)
    @exercises = Exercise.order(:name)
  end

  def create
    @session = Session.new(session_params)
    @session.session_shape = interval_work_shape

    if @session.save
      redirect_to @session, notice: "Session logged."
    else
      @exercises = Exercise.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def show
    @session = Session.find(params[:id])
    @calculator = Progression::Calculator.for(@session)
  end

  private

  def interval_work_shape
    SessionShape.find_or_create_by!(name: SessionShape::INTERVAL_WORK, user_id: nil)
  end

  def session_params
    params.expect(session: [ :date, :exercise_id, :planned_weight_kg,
                             :planned_work_seconds, :planned_rest_seconds, :planned_sets, :notes ])
  end
end
