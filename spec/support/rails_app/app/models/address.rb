class Address < ApplicationRecord
  belongs_to :user

  validates :street, :city, :state_code, :zip_code, :country_code, presence: true
end
