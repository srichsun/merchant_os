class Tenant < ApplicationRecord
  # A tenant is one merchant's store. Its products, orders, etc. are scoped to it
  # via acts_as_tenant on those models (added as we build them).
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy

  validates :name, presence: true
end
