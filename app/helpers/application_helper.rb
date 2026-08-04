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

  # Builds a pagination link that preserves whatever filters are already in the query string
  # (year/month/equipment_id/exercise_id, or nothing at all) while overriding the page number —
  # works against any base path, so the same session-history partial can paginate both the
  # owner's /sessions and the token-scoped /shared/:token/sessions without route-specific code.
  def paginated_url(base_url, page)
    # request.query_parameters has string keys ("page" => "1") — merging with a symbol :page
    # would add a second, distinct key instead of overwriting it, producing "page=1&page=2".
    "#{base_url}?#{request.query_parameters.merge("page" => page).to_query}"
  end
end
