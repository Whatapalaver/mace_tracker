class ExercisesController < ApplicationController
  def index
    @exercises = Exercise.order(:name)
  end

  def new
    @exercise = Exercise.new
  end

  def create
    @exercise = Exercise.new(exercise_params)

    if @exercise.save
      redirect_to exercises_path, notice: "Exercise added."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def exercise_params
    params.expect(exercise: [ :name, :arm, :notes ])
  end
end
