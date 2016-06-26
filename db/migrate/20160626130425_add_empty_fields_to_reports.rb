class AddEmptyFieldsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :empty_html, :boolean, default: false
  end
end
