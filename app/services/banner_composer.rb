require "tmpdir"

# Composites a real, scannable QR — centered on a clean rounded white card —
# onto an AI-generated campaign banner, so the shared banner itself carries a
# working QR while keeping the nice illustrated look.
class BannerComposer
  W = 1200
  H = 675
  QR = 320        # QR pixel size
  PAD = 30        # white padding around the QR inside the card
  RADIUS = 26     # card corner radius

  def initialize(ai_bytes:, qr_url:)
    @ai_bytes = ai_bytes
    @qr_url = qr_url
  end

  # Returns composited PNG bytes, or the original AI bytes on any failure.
  def call
    require "mini_magick"
    card = QR + PAD * 2

    Dir.mktmpdir do |dir|
      qr_path     = File.join(dir, "qr.png")
      card_path   = File.join(dir, "card.png")
      carded_path = File.join(dir, "carded.png")
      bg_path     = File.join(dir, "bg.png")
      out_path    = File.join(dir, "out.png")

      # 1) QR PNG (small quiet zone; the card adds the visual padding).
      File.binwrite(qr_path, ApplicationController.helpers.qr_png(@qr_url, color: "1A1A1A", size: QR))

      # 2) Rounded white card canvas.
      MiniMagick::Tool::Convert.new do |c|
        c.size "#{card}x#{card}"
        c << "xc:none"
        c.fill "white"
        c.draw "roundrectangle 0,0,#{card - 1},#{card - 1},#{RADIUS},#{RADIUS}"
        c << card_path
      end

      # 3) QR centered on the card.
      MiniMagick::Tool::Composite.new do |c|
        c.gravity "center"
        c << qr_path
        c << card_path
        c << carded_path
      end

      # 4) Normalize the banner to 1200x675.
      bg = MiniMagick::Image.read(@ai_bytes)
      bg.combine_options do |c|
        c.resize "#{W}x#{H}^"
        c.gravity "center"
        c.extent "#{W}x#{H}"
      end
      bg.write(bg_path)

      # 5) Composite the card centered in the right half of the banner.
      MiniMagick::Tool::Composite.new do |c|
        c.gravity "East"
        c.geometry "+150+0"
        c << carded_path
        c << bg_path
        c << out_path
      end

      File.binread(out_path)
    end
  rescue => e
    Rails.logger.error("[BannerComposer] #{e.class}: #{e.message}")
    @ai_bytes
  end
end
