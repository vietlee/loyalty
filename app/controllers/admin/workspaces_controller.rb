module Admin
  class WorkspacesController < BaseController
    before_action :set_workspace, only: [:show, :update, :approve, :suspend, :reactivate]

    def index
      ActsAsTenant.without_tenant do
        scope = Workspace.order(created_at: :desc)
        @status = params[:status] if Workspace::STATUSES.include?(params[:status])
        scope = scope.where(status: @status) if @status
        @workspaces = scope.to_a
        @counts = Workspace.group(:status).count
      end
    end

    def show
      ActsAsTenant.with_tenant(@workspace) do
        @members_count = Member.count
        @points_issued = PointTransaction.credits.sum(:amount)
        @program = @workspace.program
      end
    end

    def update
      if @workspace.update(workspace_params)
        redirect_to admin_workspace_path(@workspace), notice: "Đã cập nhật workspace."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def approve    = transition("active",    "Đã duyệt workspace.")
    def suspend    = transition("suspended", "Đã tạm ngưng workspace.")
    def reactivate = transition("active",    "Đã kích hoạt lại workspace.")

    private

    def nav_key = :workspaces

    def set_workspace
      ActsAsTenant.without_tenant { @workspace = Workspace.friendly.find(params[:id]) }
    end

    def transition(status, msg)
      @workspace.update!(status: status)
      redirect_back fallback_location: admin_workspaces_path, notice: msg
    end

    def workspace_params
      params.require(:workspace).permit(:status, :plan)
    end
  end
end
