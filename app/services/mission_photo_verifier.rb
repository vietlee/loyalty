# AI verification of a photo-proof mission submission (Google review / social
# share screenshot). Calls Claude vision, stores the verdict on the progress
# record, and — when confident — auto-approves or auto-rejects. Anything the AI
# is unsure about (or any error) is left pending for the manual merchant queue.
class MissionPhotoVerifier
  # Confidence thresholds for acting automatically.
  APPROVE_THRESHOLD = 0.80
  REJECT_THRESHOLD  = 0.85

  def initialize(mission_progress)
    @mp = mission_progress
    @mission = mission_progress.mission
    @workspace = mission_progress.workspace
  end

  def call
    return unless @mp.pending? && @mp.photo.attached?

    verdict = ClaudeService.safe_call(fallback: nil) do
      bytes = @mp.photo.download
      media = @mp.photo.content_type.presence || "image/jpeg"
      ClaudeService.new(model: ClaudeService::OPUS, max_tokens: 400)
                   .vision_json(prompt, image_bytes: bytes, media_type: media)
    end

    return if verdict.blank? # no key / API error → stays pending for manual review

    @mp.update_columns(ai_verdict: verdict.slice("verdict", "confidence", "reason"),
                       updated_at: Time.current)

    decision   = verdict["verdict"].to_s
    confidence = verdict["confidence"].to_f

    if decision == "approve" && confidence >= APPROVE_THRESHOLD
      @mp.approve!(reviewer: nil, ai: true)
    elsif decision == "reject" && confidence >= REJECT_THRESHOLD
      @mp.reject!(reviewer: nil, reason: ai_reason(verdict))
    end
    # uncertain / low-confidence → leave pending (manual queue handles it)
  end

  private

  def ai_reason(verdict) = "AI: #{verdict['reason'].presence || 'không hợp lệ'}"

  def prompt
    shop = @workspace.name
    if @mission.mission_type == "review"
      <<~PROMPT
        Bạn là hệ thống kiểm duyệt minh chứng cho chương trình khách hàng thân thiết.
        Ảnh đính kèm phải là ảnh chụp màn hình một ĐÁNH GIÁ GOOGLE (Google Review/Maps)
        thật cho doanh nghiệp tên "#{shop}". Hợp lệ khi: thấy giao diện Google review,
        có số sao, và nội dung/tên cửa hàng khớp hoặc liên quan "#{shop}".
        Không hợp lệ khi: ảnh mờ/không đọc được, không phải Google review, review cho
        nơi khác, hoặc là ảnh ngẫu nhiên/không liên quan.
        Trả về JSON: {"verdict":"approve|reject|uncertain","confidence":0.0-1.0,"reason":"ngắn gọn tiếng Việt"}.
      PROMPT
    else
      platform = Mission::PLATFORM_LABELS[@mp.platform] || @mp.platform || "mạng xã hội"
      <<~PROMPT
        Bạn là hệ thống kiểm duyệt minh chứng cho chương trình khách hàng thân thiết.
        Ảnh đính kèm phải là ảnh chụp màn hình một BÀI ĐĂNG/CHIA SẺ trên #{platform}
        có nhắc tới hoặc gắn thẻ doanh nghiệp "#{shop}".
        Hợp lệ khi: thấy đúng giao diện #{platform}, là bài đăng/chia sẻ công khai,
        có nhắc tên/thẻ cửa hàng "#{shop}".
        Không hợp lệ khi: ảnh mờ/không đọc được, không phải #{platform}, không nhắc
        tới cửa hàng, hoặc ảnh không liên quan.
        Trả về JSON: {"verdict":"approve|reject|uncertain","confidence":0.0-1.0,"reason":"ngắn gọn tiếng Việt"}.
      PROMPT
    end
  end
end
