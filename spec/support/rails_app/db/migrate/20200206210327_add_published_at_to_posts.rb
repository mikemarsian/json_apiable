class AddPublishedAtToPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :posts, :published_at, :datetime
    add_column :posts, :subscribers_only, :boolean
  end
end
