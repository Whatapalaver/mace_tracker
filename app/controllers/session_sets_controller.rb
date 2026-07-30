class SessionSetsController < ApplicationController
  before_action :set_session

  def new
    @session_set = @session.session_sets.build
  end

  def create
    @session_set = @session.session_sets.build(session_set_params)
    @session_set.set_number = next_set_number

    if @session_set.save
      redirect_to @session, notice: "Set logged."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_session
    @session = Session.find(params[:session_id])
  end

  def next_set_number
    (@session.session_sets.maximum(:set_number) || 0) + 1
  end

  def session_set_params
    params.expect(session_set: [ :reps, :weight_kg, :duration_seconds, :rest_seconds_actual ])
  end
end
