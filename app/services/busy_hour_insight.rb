# Generates a short Vietnamese suggestion about a shop's busy hours from an
# aggregated weekday×hour matrix (counts only — never raw customer rows). Stores
# the result on a WorkspaceInsight row. Falls back to a static heuristic sentence
# when Claude isn't configured or errors, so the panel is never empty.
class BusyHourInsight
  KIND = "busy_hour"

  def initialize(workspace, matrix:, busiest_slot:, range: nil)
    @workspace = workspace
    @matrix = matrix
    @slot = busiest_slot
    @range = range
  end

  # Run synchronously (called from a job). Persists the insight and returns it.
  def generate!
    body = ClaudeService.safe_call(fallback: nil) { ai_body } || heuristic_body

    insight = WorkspaceInsight.find_or_initialize_by(workspace: @workspace, kind: KIND)
    insight.update!(body: body, generated_at: Time.current, status: "ready",
                    range_from: @range&.dig(:from), range_to: @range&.dig(:to))
    insight
  end

  private

  DOW_VI = %w[Chủ\ Nhật Thứ\ Hai Thứ\ Ba Thứ\ Tư Thứ\ Năm Thứ\ Sáu Thứ\ Bảy].freeze

  def ai_body
    return heuristic_body if @slot.nil?
    prompt = <<~PROMPT
      Cửa hàng "#{@workspace.name}" có dữ liệu lượt mua theo thứ trong tuần và giờ trong ngày như sau
      (mảng 7 dòng, mỗi dòng là 24 số đếm theo giờ 0–23, dòng 0 = Chủ Nhật):
      #{@matrix.map { |r| r[:hours] }.inspect}
      Khung đông nhất: #{DOW_VI[@slot[:dow]]} lúc #{@slot[:hour]}h (#{@slot[:count]} lượt).
      Hãy viết 1–2 câu tiếng Việt ngắn gọn, thực tế, gợi ý cho chủ quán về khung giờ đông khách
      và một hành động nên làm (ví dụ: bố trí nhân sự, mở happy hour giờ vắng, đẩy khuyến mãi).
      Chỉ trả về câu văn, không markdown, không tiêu đề.
    PROMPT
    text = ClaudeService.new(model: ClaudeService::OPUS, max_tokens: 300).text(prompt)
    text.presence || heuristic_body
  end

  def heuristic_body
    return "Chưa đủ dữ liệu lượt mua để phân tích khung giờ. Hãy quay lại khi có thêm giao dịch." if @slot.nil?
    "Khung đông khách nhất là #{DOW_VI[@slot[:dow]]} lúc #{@slot[:hour]}h. " \
      "Cân nhắc tăng nhân sự vào khung này và mở ưu đãi giờ vàng cho các khung vắng hơn."
  end
end
