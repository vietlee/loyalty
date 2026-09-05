module Merchant
  class BroadcastsController < BaseController
    before_action :require_manager!, except: [:index]

    def index
      @broadcasts = current_workspace.broadcasts.recent.to_a
    end

    def new
      load_audience(params[:segment], params[:outlet], params[:q])
      @count     = @audience_scope.count
      @broadcast = Broadcast.new(segment_key: @segment)
    end

    def create
      bp = params[:broadcast] || {}
      load_audience(bp[:segment_key], bp[:audience_outlet_id], bp[:audience_query])
      @broadcast = current_workspace.broadcasts.new(
        broadcast_params.merge(segment_key: @segment, created_by: current_user,
                               audience_label: @audience_label,
                               audience_outlet_id: @outlet&.id, audience_query: @q.presence)
      )
      members = @audience_scope.to_a
      @count  = members.size

      if members.empty?
        @broadcast.errors.add(:base, "Nhóm khách này chưa có ai — không thể gửi.")
        return render :new, status: :unprocessable_entity
      end

      sched = parse_schedule(params[:scheduled_at])
      if sched && sched > Time.current
        @broadcast.scheduled_at = sched
        if @broadcast.save
          return redirect_to merchant_broadcasts_path,
                             notice: "Đã lên lịch gửi vào #{l(sched, format: :short)}."
        end
      elsif @broadcast.save
        @broadcast.deliver!(members)
        return redirect_to merchant_broadcasts_path, notice: "Đã gửi tới #{@broadcast.sent_count} khách."
      end
      render :new, status: :unprocessable_entity
    end

    private

    def nav_key = :broadcasts

    # Resolve the filtered audience (segment + branch + search) once, and build the
    # display name, from whichever params the request carries (query on :new, nested
    # broadcast[...] hidden fields on :create). Sets @segment, @outlet, @q,
    # @audience_scope and @audience_label.
    def load_audience(segment, outlet_id, q)
      @segment = MemberSegments::PRESETS.key?(segment) ? segment : "all"
      @outlet  = current_workspace.outlets.find_by(id: outlet_id) if outlet_id.present?
      @q       = q.to_s.strip
      @audience_scope = MemberSegments.audience(segment: @segment, outlet_id: @outlet&.id, q: @q)
      @audience_label = MemberSegments.audience_label(segment: @segment, outlet: @outlet, q: @q)
    end

    def broadcast_params
      params.require(:broadcast).permit(:title, :body)
    end

    def parse_schedule(raw)
      return nil if raw.blank?
      Time.zone.parse(raw.to_s)
    rescue ArgumentError
      nil
    end
  end
end
