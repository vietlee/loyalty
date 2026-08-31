module QrHelper
  # Renders `data` as a scalable QR SVG. `color` is a hex string without '#'.
  def qr_svg(data, color: "1A1A1A", size: 220)
    qr = RQRCode::QRCode.new(data.to_s, level: :m)
    svg = qr.as_svg(offset: 0, color: color, shape_rendering: "crispEdges",
                    standalone: true, use_path: true, viewbox: true)
    svg.sub("<svg",
      %(<svg width="#{size}" height="#{size}" style="width:#{size}px;height:#{size}px;display:block")
    ).html_safe
  end
end
