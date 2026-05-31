class OrderMailer < ApplicationMailer
  # Let the store owner know a new order has been paid
  def paid_notification(order)
    @order = order
    owner = order.tenant.users.owner.first
    mail(to: owner.email, subject: "Order ##{order.id} was paid")
  end

  # Receipt for the buyer
  def customer_confirmation(order)
    @order = order
    mail(to: order.customer_email, subject: "Your order ##{order.id} is confirmed")
  end
end
