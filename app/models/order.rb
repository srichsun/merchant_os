class Order < ApplicationRecord
  include AASM

  acts_as_tenant :tenant
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0, only_integer: true }

  before_validation :set_total, on: :create

  # Order lifecycle. AASM wraps each transition (and its callbacks) in a DB
  # transaction, so if decrementing stock fails the whole "pay" rolls back.
  aasm do
    state :pending, initial: true
    state :paid, :shipped, :cancelled

    event :pay do
      # Take the stock now; raises InsufficientStock if there isn't enough,
      # which aborts the transition and leaves the order pending.
      transitions from: :pending, to: :paid, after: :decrement_stock
    end

    event :ship do
      transitions from: :paid, to: :shipped
    end

    event :cancel do
      transitions from: :pending, to: :cancelled
    end
  end

  private

  def set_total
    self.total_cents = product.price_cents * quantity if product && quantity
  end

  def decrement_stock
    product.sell!(quantity)
  end
end
