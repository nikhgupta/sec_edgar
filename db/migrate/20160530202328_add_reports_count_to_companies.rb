class AddReportsCountToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :reports_count, :integer, default: 0
    add_column :companies, :processed_count, :integer, default: 0
  end
end
