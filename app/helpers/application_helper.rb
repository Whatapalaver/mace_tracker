module ApplicationHelper
  # A per-weight line chart can have as many series as the exercise has distinct weights ever
  # logged against it — real historic data easily reaches 15-20 (odd kettlebell/mace weights
  # accumulate over years) — so the palette needs far more entries than the 4 named theme colors,
  # or Chart.js silently falls back to grey once it runs out. The first 4 are the named theme
  # colors (rust/brass/moss/crimson); the rest are 36 hues spaced evenly around the color wheel,
  # avoiding those 4, at higher saturation with alternating lightness bands so neighboring series
  # stay visually distinct even in a long run of similar hues. Yellow/green hues get pulled a bit
  # darker than the rest, since WCAG luminance weighs green heavily — without that they read as
  # washed out against the chart's white background even at the same HSL lightness as everything
  # else. Every entry clears 2.4:1 contrast against white.
  CHART_COLORS = [
    "#b5432b", "#a9793c", "#4b6b3a", "#a3261e",
    "#974820", "#b98927", "#6d5c17", "#7e781b", "#97a022", "#475412",
    "#5d7e1b", "#65a022", "#1f5412", "#217e1b", "#22a02a", "#12541f",
    "#1b7e3c", "#22a05d", "#12543a", "#1b7e64", "#27b9a6", "#176d6d",
    "#208897", "#2792b9", "#174b6d", "#205897", "#2758b9", "#17286d",
    "#202897", "#3127b9", "#28176d", "#482097", "#6b27b9", "#4b176d",
    "#782097", "#a627b9", "#6d176d", "#972088", "#b92792", "#6d174b"
  ].freeze

  def chart_colors
    CHART_COLORS
  end
end
