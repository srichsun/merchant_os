module Storefront
  class OrdersController < BaseController
    def new
      @product = Product.find(params[:product_id])
      @order = Order.new(product: @product, quantity: 1)
    end

    # Create a pending order and hand off to the chosen gateway. The order is
    # only marked paid when that gateway's verified webhook comes back.
    def create
      product = Product.find(params[:product_id])
      order = Order.create!(
        product: product,
        quantity: order_params[:quantity].presence || 1,
        customer_email: order_params[:customer_email],
        customer_name: order_params[:customer_name],
        phone: order_params[:phone],
        shipping_address: order_params[:shipping_address],
        payment_ref: generate_payment_ref
      )

      if params[:payment_method] == "ecpay"
        checkout_via_ecpay(order)
      else
        redirect_to StripeCheckout.session_url(
          order: order,
          success_url: storefront_store_url(@store, checkout: "success"),
          cancel_url: storefront_store_checkout_url(@store, product.id)
        ), allow_other_host: true
      end
    end

    private

    # Render an auto-submitting form that posts the signed params to ECPay.
    def checkout_via_ecpay(order)
      @action_url = Ecpay.checkout_url
      @fields = Ecpay.checkout_params(
        order: order,
        return_url: payments_ecpay_callback_url,
        client_back_url: storefront_store_url(@store, checkout: "success")
      )
      render :pay
    end

    def order_params
      params.fetch(:order, {})
            .permit(:quantity, :customer_email, :customer_name, :phone, :shipping_address)
    end

    # ECPay's MerchantTradeNo: <= 20 alphanumeric chars, unique per order
    def generate_payment_ref
      "MOS#{Time.current.strftime('%y%m%d%H%M%S')}#{100 + SecureRandom.random_number(900)}"
    end
  end
end
