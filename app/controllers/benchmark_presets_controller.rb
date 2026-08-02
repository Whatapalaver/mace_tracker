class BenchmarkPresetsController < ApplicationController
  include SessionShapeOptions

  def index
    @benchmark_presets = BenchmarkPreset.order(:name)
  end

  def new
    @benchmark_preset = BenchmarkPreset.new
    @exercises = Exercise.order(:name)
    @session_shapes = session_shapes
  end

  def create
    @benchmark_preset = BenchmarkPreset.new(benchmark_preset_params)

    if @benchmark_preset.save
      redirect_to benchmark_presets_path, notice: "Benchmark preset added."
    else
      @exercises = Exercise.order(:name)
      @session_shapes = session_shapes
      render :new, status: :unprocessable_content
    end
  end

  private

  def benchmark_preset_params
    params.expect(benchmark_preset: [ :name, :exercise_id, :session_shape_id, :weight_kg,
                                      :work_seconds, :rest_seconds, :sets_count,
                                      :reps, :reps_per_minute ])
  end
end
