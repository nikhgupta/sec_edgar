class Report < ActiveRecord::Base
  belongs_to :company
  validates_uniqueness_of :accession, scope: [:filed_at, :company_id]

  def raw_path
    "edgar/data/#{company.cik.to_i}/#{accession}.txt"
  end

  def index_path
    "edgar/data/#{company.cik.to_i}/#{accession}-index.htm"
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

  def add_dropbox_file(name, tmp_path, data, overwrite = false)
    to_path = "/Annual Reports/#{File.basename(tmp_path)}"
    File.open(tmp_path, "wb"){|f| f << data}
    data = File.open(tmp_path){|f| Dropbox::CLIENT.put_file to_path, f, overwrite}
    data = Dropbox::CLIENT.shares(data["path"], false)
    uri  = URI.parse(data['url']); uri.query = nil
    update_attribute "#{name}_url", uri.to_s
  end
end
