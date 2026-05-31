module Storefront
  class OrdersController < BaseController
    # Mock checkout: place an order and "pay" it immediately. Paying takes stock
    # under a pessimistic lock and kicks off the Sidekiq notification chain.
    # A real Stripe/ECPay flow would replace the pay! call with a webhook later.
    def create
      product = Product.find(params[:product_id])
      order = Order.create!(product: product, quantity: 1)
      order.pay!
      redirect_to storefront_store_path(@store), notice: "Paid! Order ##{order.id} placed."
    rescue Product::InsufficientStock
      redirect_to storefront_store_path(@store), alert: "Sorry, that item just sold out."
    end
  end
end
