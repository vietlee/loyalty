module Merchant
  class OutletsController < BaseController
    before_action :require_manager!, except: [:index]
    before_action :set_outlet, only: [:edit, :update, :destroy]

    def index
      @outlets = current_workspace.outlets.order(:name)
      @outlet  = Outlet.new(active: true)
    end

    def create
      unless current_workspace.can_add_outlet?
        return redirect_to merchant_outlets_path,
          alert: "Gói #{current_workspace.plan_record.name} chỉ cho phép #{current_workspace.outlet_limit} chi nhánh. Nâng cấp gói để thêm."
      end
      @outlet = current_workspace.outlets.new(outlet_params)
      if @outlet.save
        redirect_to merchant_outlets_path, notice: "Đã thêm chi nhánh “#{@outlet.name}”."
      else
        @outlets = current_workspace.outlets.order(:name)
        render :index, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @outlet.update(outlet_params)
        redirect_to merchant_outlets_path, notice: "Đã cập nhật chi nhánh."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @outlet.destroy
      redirect_to merchant_outlets_path, notice: "Đã xoá chi nhánh."
    end

    private

    def nav_key = :outlets

    def set_outlet
      @outlet = current_workspace.outlets.find(params[:id])
    end

    def outlet_params
      params.require(:outlet).permit(:name, :code, :address, :phone, :active)
    end
  end
end
