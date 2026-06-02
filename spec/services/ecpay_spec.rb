require "rails_helper"

RSpec.describe Ecpay do
  it "signs params so they verify as a valid callback" do
    params = { "MerchantID" => "2000132", "MerchantTradeNo" => "MOS1", "TotalAmount" => 100 }
    signed = params.merge("CheckMacValue" => Ecpay.check_mac_value(params))

    expect(Ecpay.valid_callback?(signed)).to be(true)
  end

  it "rejects a payload tampered after signing" do
    params = { "MerchantTradeNo" => "MOS1", "TotalAmount" => 100 }
    signed = params.merge("CheckMacValue" => Ecpay.check_mac_value(params))
    signed["TotalAmount"] = 1

    expect(Ecpay.valid_callback?(signed)).to be(false)
  end
end
