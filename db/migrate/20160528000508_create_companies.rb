class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string  :cik
      t.string  :symbol
      t.string  :name
      t.string  :sector
      t.string  :industry
      t.decimal :last_sale, precision: 8, scale: 2, default: 0
      t.bigint  :market_capital, default: 0, precision: 11
      t.integer :ipo_year

      t.boolean :listed, default: true

      t.timestamps null: false
    end
  end
end
