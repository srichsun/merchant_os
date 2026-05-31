class Product < ApplicationRecord
  # Raised when a buyer tries to take more units than are in stock
  class InsufficientStock < StandardError; end

  # Scopes every query to the current store; also adds belongs_to :tenant
  acts_as_tenant :tenant

  validates :name, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :stock, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  # Sell `quantity` units while preventing overselling under concurrent buyers.
  #
  # with_lock wraps this in a transaction and does SELECT ... FOR UPDATE, so two
  # requests racing for the last unit are serialized: the second one waits, then
  # re-reads the now-updated stock and is rejected instead of going negative.
  def sell!(quantity = 1)
    with_lock do
      raise InsufficientStock if stock < quantity

      update!(stock: stock - quantity)
    end
  end

  # price_cents is the source of truth; this is just for display
  def price
    price_cents / 100.0
  end
end
