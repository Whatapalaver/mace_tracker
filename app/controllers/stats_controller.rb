class StatsController < ApplicationController
  def show
    @exercises = Exercise.order(:name)
    @exercise = Exercise.find(params[:exercise_id]) if params[:exercise_id].present?
    @stats = Progression::LifetimeStats.new(exercise: @exercise)
  end
end
