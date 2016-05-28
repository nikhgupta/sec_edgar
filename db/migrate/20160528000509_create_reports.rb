class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.references :company, index: true, foreign_key: true
      t.string :accession
      t.string :form_type

      t.datetime :filed_at
      t.datetime :processed_at
      t.timestamps null: false
    end
  end
end
