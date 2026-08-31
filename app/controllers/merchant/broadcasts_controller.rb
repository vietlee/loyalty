module Merchant
  class BroadcastsController < BaseController
    before_action :require_manager!, except: [:index]

    def index
      @broadcasts = current_workspace.broadcasts.recent.to_a
    end

    def new
      @segment = MemberSegments::PRESETS.key?(params[:segment]) ? params[:segment] : "all"
      @count   = MemberSegments.resolve(@segment).count
      @broadcast = Broadcast.new(segment_key: @segment)
    end

    def create
      @segment = MemberSegments::PRESETS.key?(params[:broadcast][:segment_key]) ? params[:broadcast][:segment_key] : "all"
      @broadcast = current_workspace.broadcasts.new(broadcast_params.merge(segment_key: @segment, created_by: current_user))
      if @broadcast.save
        members = MemberSegments.resolve(@segment).to_a
        @broadcast.deliver!(members)
        redirect_to merchant_broadcasts_path, notice: "Đã gửi tới #{@broadcast.sent_count} khách."
      else
        @count = MemberSegments.resolve(@segment).count
        render :new, status: :unprocessable_entity
      end
    end

    private

    def nav_key = :broadcasts

    def broadcast_params
      params.require(:broadcast).permit(:title, :body)
    end
  end
end
