require "rails_helper"

RSpec.describe "Stripe webhook", type: :request do
  let(:store) { create(:tenant) }

  def create_order(ref)
    ActsAsTenant.with_tenant(store) do
      product = create(:product, tenant: store, stock: 5)
      Order.create!(product: product, quantity: 1, customer_email: "b@example.com", payment_ref: ref)
    end
  end

  def completed_event(ref)
    Stripe::Event.construct_from(
      type: "checkout.session.completed",
      data: { object: { client_reference_id: ref } }
    )
  end

  it "marks the order paid on checkout.session.completed" do
    order = create_order("MOSWH0001")
    allow(Stripe::Webhook).to receive(:construct_event).and_return(completed_event(order.payment_ref))

    post payments_stripe_webhook_path, params: "{}", headers: { "Stripe-Signature" => "sig" }

    expect(response).to have_http_status(:ok)
    expect(order.reload.aasm_state).to eq("paid")
  end

  it "rejects a forged request with a bad signature" do
    allow(Stripe::Webhook).to receive(:construct_event)
      .and_raise(Stripe::SignatureVerificationError.new("bad", "sig"))

    post payments_stripe_webhook_path, params: "{}", headers: { "Stripe-Signature" => "bad" }

    expect(response).to have_http_status(:bad_request)
  end
end
