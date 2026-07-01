module Storefront
  # Storefront customer-service chat. Inherits BaseController, so the tenant is
  # already resolved from the URL slug — the agent's tool queries stay scoped to
  # this store.
  #
  # Non-blocking: echo the question + a placeholder immediately, then run the
  # agent in a background job that pushes the reply back over ActionCable.
  class ChatController < BaseController
    def create
      @message = params[:message].to_s.strip
      @conversation_id = params[:conversation_id].to_s
      @reply_dom_id = "reply_#{SecureRandom.hex(8)}"

      if @message.present?
        CustomerServiceReplyJob.perform_later(
          tenant_id: @store.id,
          conversation_id: @conversation_id,
          message: @message,
          reply_dom_id: @reply_dom_id,
          product_name: current_product_name
        )
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to storefront_store_path(@store) }
      end
    end

    private

    # The product the customer is chatting from (tenant-scoped), if any.
    def current_product_name
      return if params[:product_id].blank?

      Product.find_by(id: params[:product_id])&.name
    end
  end
end
