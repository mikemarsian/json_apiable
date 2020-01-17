class CreateAddresses < ActiveRecord::Migration[6.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: false
      t.string :street, null: false
      t.string :city, null: false
      t.string :state_code, null: false
      t.string :zip_code, null: false
      t.string :country_code, null: false
      t.timestamps
    end
  end
end
