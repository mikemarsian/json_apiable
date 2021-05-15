class Post < ApplicationRecord
  has_many :comments, dependent: :destroy
  has_many :tags, class_name: 'PostTag', dependent: :destroy
  belongs_to :user

  validates :title, presence: true,
            length: { minimum: 5 }

  accepts_nested_attributes_for :tags


  enum status: %i[ draft in_review published ]
end
