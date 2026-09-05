# Composites a real, scannable QR (on a clean white card) onto an AI-generated
# campaign banner, so the shared banner itself carries the working QR — keeping
# the nice illustrated look while the code actually resolves.
class BannerComposer
  W = 1200
  H = 675

  def initialize(ai_bytes:, qr_url:)
    @ai_bytes = ai_bytes
    @qr_url = qr_url
  end

  # Returns composited PNG bytes, or the original AI bytes on any failure.
  def call
    require "mini_magick"
    qr_png = ApplicationController.helpers.qr_png(@qr_url, color: "1A1A1A", size: 300)

    bg = MiniMagick::Image.read(@ai_bytes)
    bg.combine_options do |c|
      c.resize "#{W}x#{H}^"
      c.gravity "center"
      c.extent "#{W}x#{H}"
    end

    qr = MiniMagick::Image.read(qr_png)
    qr.combine_options do |c|
      c.bordercolor "white"
      c.border "22"           # white quiet-zone card around the QR
    end

    out = bg.composite(qr) do |c|
      c.compose "Over"
      c.gravity "East"
      c.geometry "+70+0"      # right side, vertically centered
    end
    out.to_blob
  rescue => e
    Rails.logger.error("[BannerComposer] #{e.class}: #{e.message}")
    @ai_bytes
  end
end
