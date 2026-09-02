module Merchant
  class StampCardsController < BaseController
    before_action :require_manager!

    def create
      card = current_workspace.stamp_cards.new(card_params)
      if card.save
        redirect_to merchant_gamification_path, notice: "Đã tạo thẻ tem “#{card.title}”."
      else
        redirect_to merchant_gamification_path, alert: card.errors.full_messages.to_sentence
      end
    end

    def update
      card = current_workspace.stamp_cards.find(params[:id])
      if card.update(card_params)
        redirect_to merchant_gamification_path, notice: "Đã cập nhật thẻ tem “#{card.title}”."
      else
        redirect_to merchant_gamification_path, alert: card.errors.full_messages.to_sentence
      end
    end

    def destroy
      current_workspace.stamp_cards.find(params[:id]).destroy
      redirect_to merchant_gamification_path, notice: "Đã xoá thẻ tem."
    end

    private

    def nav_key = :gamification

    def card_params
      params.require(:stamp_card).permit(:title, :description, :icon, :target_count, :reward_id, :active)
    end
  end
end
