class Tenant < ApplicationRecord
  # A tenant is one merchant's store. Its products, orders, etc. are scoped to it
  # via acts_as_tenant on those models (added as we build them).
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  before_validation :set_slug, on: :create
  before_validation :normalize_instagram_handle

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Used in the public storefront URL: /s/:slug
  def to_param
    slug
  end

  # Link out to the influencer's real (public) Instagram profile.
  def instagram_url
    "https://www.instagram.com/#{instagram_handle}/" if instagram_handle.present?
  end

  private

  def set_slug
    self.slug ||= name&.parameterize
  end

  # Store the bare handle so "@dane", " dane " and "dane" all end up as "dane".
  def normalize_instagram_handle
    self.instagram_handle = instagram_handle&.strip&.delete_prefix("@").presence
  end
end
