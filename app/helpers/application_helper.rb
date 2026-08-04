module ApplicationHelper
  # A per-weight line chart can have as many series as the exercise has distinct weights ever
  # logged against it — real historic data easily reaches 15-20 (odd kettlebell/mace weights
  # accumulate over years) — so the palette needs far more entries than the 4 named theme colors,
  # or Chart.js silently falls back to grey once it runs out. The first 4 are the named theme
  # colors (rust/brass/moss/crimson); the rest are 36 hues spaced evenly around the color wheel,
  # avoiding those 4, at higher saturation with alternating lightness bands so neighboring series
  # stay visually distinct even in a long run of similar hues.
  CHART_COLORS = [
    "#b5432b", "#a9793c", "#4b6b3a", "#a3261e",
    "#a55127", "#d3a445", "#7c691d", "#a59d27", "#cad345", "#697c1d",
    "#7ba527", "#91d345", "#307c1d", "#2fa527", "#45d34f", "#1d7c30",
    "#27a551", "#45d388", "#1d7c56", "#27a584", "#45d3c0", "#1d7c7c",
    "#2794a5", "#45add3", "#1d567c", "#2762a5", "#4575d3", "#1d307c",
    "#272fa5", "#4f45d3", "#301d7c", "#5127a5", "#8845d3", "#561d7c",
    "#8427a5", "#c045d3", "#7c1d7c", "#a52794", "#d345ad", "#7c1d56"
  ].freeze

  def chart_colors
    CHART_COLORS
  end
end
