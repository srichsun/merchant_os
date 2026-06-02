# Builds a Stripe hosted Checkout Session for an order and returns its URL.
# The order is only marked paid once Stripe's verified webhook arrives
# (Payments::StripeController), never from the browser redirect.
class StripeCheckout
  def self.session_url(order:, success_url:, cancel_url:)
    session = Stripe::Checkout::Session.create(
      mode: "payment",
      client_reference_id: order.payment_ref,
      customer_email: order.customer_email,
      line_items: [ {
        quantity: order.quantity,
        price_data: {
          currency: "twd",
          unit_amount: order.product.price_cents, # TWD smallest unit
          product_data: { name: order.product.name }
        }
      } ],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: { payment_ref: order.payment_ref }
    )
    session.url
  end
end
