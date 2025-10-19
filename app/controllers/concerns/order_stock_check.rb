# frozen_string_literal: true

module OrderStockCheck
  include CablecarResponses
  extend ActiveSupport::Concern

  delegate :sufficient_stock?, to: :check_stock_service

  def valid_order_line_items?
    OrderCycles::DistributedVariantsService.new(@order.order_cycle, @order.distributor).
      distributes_order_variants?(@order)
  end

  def handle_insufficient_stock
    @any_out_of_stock = false

    return if sufficient_stock?

    @any_out_of_stock = true
    @updated_variants = check_stock_service.update_line_items
  end

  def check_order_cycle_expiry(should_empty_order: true)
    return unless current_order_cycle&.closed?

    Alert.raise_with_record("Notice: order cycle closed during checkout completion", current_order)
    if should_empty_order
      current_order.empty!
      current_order.assign_order_cycle! nil
    end

    flash[:info] = I18n.t('order_cycle_closed')
    respond_to do |format|
      format.cable_ready {
        render status: :see_other, cable_ready: cable_car.redirect_to(url: main_app.shop_path)
      }
      format.json { render json: { path: main_app.shop_path }, status: :see_other }
      format.html { redirect_to main_app.shop_path, status: :see_other }
    end
  end

  private

  def check_stock_service
    @check_stock_service ||= Orders::CheckStockService.new(order: @order)
  end
end
