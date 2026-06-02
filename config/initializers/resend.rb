# Resend HTTP API key. Used by the :resend Action Mailer delivery method
# (set in production when RESEND_API_KEY is present). Unset elsewhere, so dev
# and test keep their own delivery methods.
Resend.api_key = ENV["RESEND_API_KEY"] if ENV["RESEND_API_KEY"].present?
