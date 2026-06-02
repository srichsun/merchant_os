module Payments
  # Receives ECPay's server-to-server payment notification. Plain controller:
  # no login, no tenant, no CSRF token (ECPay can't send one).
  class EcpayController < ActionController::Base
    skip_forgery_protection

    def callback
      payload = request.request_parameters

      if Ecpay.valid_callback?(payload) && payload["RtnCode"].to_i == 1
        order = Order.find_by(payment_ref: payload["MerchantTradeNo"])
        order.pay! if order&.may_pay? # idempotent: ignore duplicate notifications
        render plain: "1|OK"          # ECPay expects this exact ack
      else
        render plain: "0|ERROR"
      end
    end
  end
end
