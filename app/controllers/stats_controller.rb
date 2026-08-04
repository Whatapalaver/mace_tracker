class StatsController < ApplicationController
  include StatsExplorer

  def show
    build_stats_explorer
  end
end
