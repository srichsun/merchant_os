class Tenant < ApplicationRecord
  # A tenant is one merchant's store. Its products, orders, etc. are scoped to it
  # via acts_as_tenant on those models (added as we build them).
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  before_validation :set_slug, on: :create

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Used in the public storefront URL: /s/:slug
  def to_param
    slug
  end

  private

  def set_slug
    self.slug ||= name&.parameterize
  end
end
