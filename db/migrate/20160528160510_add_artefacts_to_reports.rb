class AddArtefactsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :pdf_url, :string
    add_column :reports, :excel_url, :string
  end
end
