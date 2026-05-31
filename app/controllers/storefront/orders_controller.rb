module Storefront
  class OrdersController < BaseController
    def new
      @product = Product.find(params[:product_id])
      @order = Order.new(product: @product, quantity: 1)
    end

    # Mock checkout: place the order and "pay" it immediately. Paying takes stock
    # under a pessimistic lock and kicks off the email/fulfillment chain.
    # A real Stripe/ECPay flow would replace pay! with a webhook later.
    def create
      product = Product.find(params[:product_id])
      order = Order.create!(
        product: product,
        quantity: order_params[:quantity].presence || 1,
        customer_email: order_params[:customer_email]
      )
      order.pay!
      redirect_to storefront_store_path(@store), notice: "Paid! Order ##{order.id} placed."
    rescue Product::InsufficientStock
      redirect_to storefront_store_path(@store), alert: "Sorry, that item just sold out."
    end

    private

    def order_params
      params.fetch(:order, {}).permit(:quantity, :customer_email)
    end
  end
end
