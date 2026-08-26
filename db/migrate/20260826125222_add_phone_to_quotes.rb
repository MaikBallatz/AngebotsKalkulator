class AddPhoneToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :phone, :string
  end
end
