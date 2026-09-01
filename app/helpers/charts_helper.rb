module ChartsHelper
  # Inline SVG bar chart (no JS/asset dependency, theme-aware via CSS vars).
  # points: [{ label:, value: }, ...]. Bars use --primary; labels use currentColor.
  def bar_chart_svg(points, height: 190, color: "var(--primary)")
    points = Array(points)
    return "".html_safe if points.empty?
    n      = points.size
    slot   = 58
    w      = n * slot
    top    = 22          # room for value labels
    bottom = height - 26 # baseline (room for month labels)
    plot_h = bottom - top
    max    = [points.map { |p| p[:value].to_i }.max, 1].max
    bar_w  = (slot * 0.52).round

    bars = points.each_with_index.map do |p, i|
      cx  = (i * slot + slot / 2.0)
      val = p[:value].to_i
      bh  = (val.to_f / max * plot_h).round
      bh  = 3 if bh < 3 && val.positive?
      y   = bottom - bh
      x   = (cx - bar_w / 2.0).round
      <<~SVG
        <rect x="#{x}" y="#{y}" width="#{bar_w}" height="#{bh}" rx="6" fill="#{color}" opacity="#{val.zero? ? 0.15 : 1}"/>
        <text x="#{cx.round}" y="#{y - 6}" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor">#{val}</text>
        <text x="#{cx.round}" y="#{height - 8}" text-anchor="middle" font-size="11" fill="currentColor" opacity=".55">#{ERB::Util.html_escape(p[:label])}</text>
      SVG
    end.join

    baseline = %(<line x1="0" y1="#{bottom}" x2="#{w}" y2="#{bottom}" stroke="currentColor" stroke-opacity=".12"/>)
    %(<svg viewBox="0 0 #{w} #{height}" width="100%" height="#{height}" preserveAspectRatio="xMidYMid meet" style="display:block; overflow:visible;" role="img">#{baseline}#{bars}</svg>).html_safe
  end
end
