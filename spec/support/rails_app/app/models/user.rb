class User < ApplicationRecord
  has_many :posts
  has_many :comments
  accepts_nested_attributes_for :posts

  attr_accessor :address
end
