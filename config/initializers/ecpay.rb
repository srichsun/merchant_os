# ECPay credentials. Defaults are ECPay's public TEST (stage) credentials,
# so the checkout flow works without a real merchant account.
Rails.application.config.x.ecpay = {
  merchant_id: ENV.fetch("ECPAY_MERCHANT_ID", "2000132"),
  hash_key: ENV.fetch("ECPAY_HASH_KEY", "5294y06JbISpM5x9"),
  hash_iv: ENV.fetch("ECPAY_HASH_IV", "v77hoKGq4kWxNNIS"),
  checkout_url: ENV.fetch("ECPAY_CHECKOUT_URL", "https://payment-stage.ecpay.com.tw/Cgi-Bin/AioCheckOut/V5")
}
