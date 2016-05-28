class Report < ActiveRecord::Base
  belongs_to :company
  validates_uniqueness_of :accession, scope: [:filed_at, :company_id]

  def raw_path
    "edgar/data/#{company.cik.to_i}/#{accession}.txt"
  end

  def excel_path
    "edgar/data/#{company.cik.to_i}/#{accession.gsub("-", '')}/Financial_Report.xlsx"
  end

  def unprocessed?
    !processed?
  end

  def processed?
    processed_at.present?
  end
end
