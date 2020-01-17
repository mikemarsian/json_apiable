class User < ApplicationRecord
  has_many :posts
  has_many :comments
  has_one :address
  accepts_nested_attributes_for :posts
  accepts_nested_attributes_for :address
end
