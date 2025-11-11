class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  # InSales validations
  validates :insales_id, presence: true, uniqueness: true, if: -> { insales_id.present? }
  validates :shop, presence: true, if: -> { shop.present? }
end
