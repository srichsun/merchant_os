require "cgi"
require "digest"

# Talks to ECPay's All-In-One checkout. Builds the signed checkout params and
# verifies the CheckMacValue on the callback so forged "paid" requests are rejected.
class Ecpay
  class << self
    def checkout_url
      config[:checkout_url]
    end

    # Params (including CheckMacValue) for the auto-submitting form -> ECPay
    def checkout_params(order:, return_url:, client_back_url:)
      params = {
        "MerchantID" => config[:merchant_id],
        "MerchantTradeNo" => order.payment_ref,
        "MerchantTradeDate" => order.created_at.strftime("%Y/%m/%d %H:%M:%S"),
        "PaymentType" => "aio",
        "TotalAmount" => order.total_cents / 100, # TWD has no subunit
        "TradeDesc" => "MerchantOS order",
        "ItemName" => "#{order.product.name} x #{order.quantity}",
        "ReturnURL" => return_url,         # server-to-server notification
        "ClientBackURL" => client_back_url, # where the buyer's browser returns
        "ChoosePayment" => "Credit",
        "EncryptType" => 1                 # 1 = SHA256
      }
      params.merge("CheckMacValue" => check_mac_value(params))
    end

    # True only if the callback really came from ECPay (signature matches)
    def valid_callback?(params)
      received = params["CheckMacValue"].to_s
      return false if received.empty?

      ActiveSupport::SecurityUtils.secure_compare(received.upcase, check_mac_value(params))
    end

    # ECPay's signature: sort params, wrap with the secret key/iv, .NET-encode, SHA256
    def check_mac_value(params)
      pairs = params.reject { |k, _| k.to_s == "CheckMacValue" }
                    .sort_by { |k, _| k.to_s.downcase }
                    .map { |k, v| "#{k}=#{v}" }
      raw = "HashKey=#{config[:hash_key]}&#{pairs.join('&')}&HashIV=#{config[:hash_iv]}"
      Digest::SHA256.hexdigest(dotnet_url_encode(raw)).upcase
    end

    private

    def config
      Rails.application.config.x.ecpay
    end

    # Mimic .NET HttpUtility.UrlEncode + lowercase, which is what ECPay hashes
    def dotnet_url_encode(str)
      CGI.escape(str).downcase
         .gsub("%2d", "-").gsub("%5f", "_").gsub("%2e", ".")
         .gsub("%21", "!").gsub("%2a", "*").gsub("%28", "(").gsub("%29", ")")
    end
  end
end
