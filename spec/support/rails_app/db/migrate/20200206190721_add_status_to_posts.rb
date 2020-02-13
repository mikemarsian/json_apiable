class AddStatusToPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :posts, :status, :integer, default: Post.statuses[:draft]
  end
end
