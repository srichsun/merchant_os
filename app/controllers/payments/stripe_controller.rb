module Payments
  # Receives Stripe's payment webhook. Plain controller: no login, no tenant, no
  # CSRF token. Stripe's library verifies the signature, so forged "paid"
  # requests are rejected.
  class StripeController < ActionController::Base
    skip_forgery_protection

    def webhook
      event = Stripe::Webhook.construct_event(
        request.body.read,
        request.env["HTTP_STRIPE_SIGNATURE"],
        ENV["STRIPE_WEBHOOK_SECRET"]
      )

      if event.type == "checkout.session.completed"
        order = Order.find_by(payment_ref: event.data.object.client_reference_id)
        order.pay! if order&.may_pay? # idempotent: ignore duplicate notifications
      end

      head :ok
    rescue Stripe::SignatureVerificationError, JSON::ParserError
      head :bad_request
    end
  end
end
