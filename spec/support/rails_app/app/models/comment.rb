class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :commenter, class_name: 'User', foreign_key: :user_id

  validates :body, presence: true,
            length: { minimum: 5 }
end
