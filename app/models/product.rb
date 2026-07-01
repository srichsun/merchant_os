class Product < ApplicationRecord
  include PgSearch::Model

  # Raised when a buyer tries to take more units than are in stock
  class InsufficientStock < StandardError; end

  # Scopes every query to the current store; also adds belongs_to :tenant
  acts_as_tenant :tenant

  # Product photo. The :card variant is a thumbnail used on listing pages;
  # variants are generated lazily and stored, so they're computed once.
  # Storefront thumbnail: small WebP so the grid loads fast. Pre-generated in the
  # seed so requests are a quick redirect, not an on-the-fly conversion.
  has_one_attached :image do |attachable|
    attachable.variant :card, resize_to_limit: [ 480, 480 ], format: :webp, saver: { quality: 72 }
  end

  # Trigram search handles partial matches and Chinese substrings without ES
  pg_search_scope :search_by_name,
                  against: :name,
                  using: { trigram: { word_similarity: true } }

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

  # --- Flash-sale helpers (price_cents is the limited sale price) ---

  def upcoming?
    sale_starts_at.present? && sale_starts_at.future?
  end

  def ended?
    sale_ends_at.present? && sale_ends_at.past?
  end

  def sold_out?
    stock.zero?
  end

  def on_sale?
    !upcoming? && !ended? && !sold_out?
  end

  # One symbol for the UI to branch on.
  def sale_status
    return :upcoming if upcoming?
    return :ended if ended?
    return :sold_out if sold_out?

    :on_sale
  end

  def original_price
    original_price_cents ? original_price_cents / 100.0 : nil
  end

  # Percent off vs the original price; nil when there's no markdown.
  def discount_percent
    return nil if original_price_cents.blank? || original_price_cents <= price_cents

    (100 - (price_cents * 100.0 / original_price_cents)).round
  end
end
