# Stripe API key — use a test key in development, a live key in production.
# When unset, Stripe calls just aren't made (checkout defaults can fall back to
# ECPay), so the app still boots fine without it.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
