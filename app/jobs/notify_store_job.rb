# First link in the post-payment chain: email the store, then hand off to fulfillment.
class NotifyStoreJob < ApplicationJob
  queue_as :default

  def perform(order)
    OrderMailer.paid_notification(order).deliver_now
    OrderMailer.customer_confirmation(order).deliver_now if order.customer_email.present?
    FulfillmentJob.perform_later(order)
  end
end
