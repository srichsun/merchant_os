module Storefront
  class OrdersController < BaseController
    def new
      @product = Product.find(params[:product_id])
      @order = Order.new(product: @product, quantity: 1)
    end

    # Create a pending order and hand off to ECPay. The order is only marked paid
    # when ECPay's verified callback comes back (Payments::EcpayController).
    def create
      product = Product.find(params[:product_id])
      order = Order.create!(
        product: product,
        quantity: order_params[:quantity].presence || 1,
        customer_email: order_params[:customer_email],
        payment_ref: generate_payment_ref
      )

      @action_url = Ecpay.checkout_url
      @fields = Ecpay.checkout_params(
        order: order,
        return_url: payments_ecpay_callback_url,
        client_back_url: storefront_store_url(@store)
      )
      render :pay
    end

    private

    def order_params
      params.fetch(:order, {}).permit(:quantity, :customer_email)
    end

    # ECPay's MerchantTradeNo: <= 20 alphanumeric chars, unique per order
    def generate_payment_ref
      "MOS#{Time.current.strftime('%y%m%d%H%M%S')}#{100 + SecureRandom.random_number(900)}"
    end
  end
end
