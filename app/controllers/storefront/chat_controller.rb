module Storefront
  # Storefront customer-service chat. Inherits BaseController, so the tenant is
  # already resolved from the URL slug — the agent's tool queries stay scoped to
  # this store.
  #
  # Synchronous MVP: the agent runs inside the request and blocks the thread for
  # a few seconds. Phase 3 moves this to a background job + Turbo Stream push.
  class ChatController < BaseController
    def create
      @message = params[:message].to_s.strip
      @reply = CustomerServiceAgent.new.respond(@message) if @message.present?

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to storefront_store_path(@store) }
      end
    end
  end
end
