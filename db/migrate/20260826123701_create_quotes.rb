class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.string :angebotstyp, null: false
      t.references :consultant, null: false, foreign_key: true
      t.string :company_name, null: false
      t.string :contact_person, null: false
      t.text :address
      t.string :position, null: false
      t.string :project_reference
      t.decimal :minimum_fee, null: false
      t.boolean :fee_rate_is_third, null: false, default: true
      t.decimal :fee_rate_percentage
      t.integer :payment_term_days, null: false, default: 10
      t.integer :volume_limit

      t.timestamps
    end
  end
end
