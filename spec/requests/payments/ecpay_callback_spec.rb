require "rails_helper"

RSpec.describe "ECPay callback", type: :request do
  let(:store) { create(:tenant) }
  let(:product) { create(:product, tenant: store, stock: 5) }
  let!(:order) { create(:order, tenant: store, product: product, payment_ref: "MOSTEST01") }

  def sign(payload)
    payload.merge("CheckMacValue" => Ecpay.check_mac_value(payload))
  end

  it "marks the order paid on a verified success callback" do
    payload = sign("MerchantTradeNo" => order.payment_ref, "RtnCode" => "1", "TradeAmt" => "100")

    post payments_ecpay_callback_path, params: payload

    expect(response.body).to eq("1|OK")
    expect(order.reload).to be_paid
  end

  it "rejects a callback whose signature doesn't match" do
    payload = sign("MerchantTradeNo" => order.payment_ref, "RtnCode" => "1")
    payload["MerchantTradeNo"] = "HACKED" # tampered after signing

    post payments_ecpay_callback_path, params: payload

    expect(response.body).to eq("0|ERROR")
    expect(order.reload).to be_pending
  end
end
