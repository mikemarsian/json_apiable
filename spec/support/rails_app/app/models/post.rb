class Post < ApplicationRecord
  has_many :comments
  belongs_to :author, class_name: 'User', foreign_key: :user_id

  validates :title, presence: true,
            length: { minimum: 5 }

  enum status: %i[ draft in_review published ]
end
