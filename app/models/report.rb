class Report < ActiveRecord::Base
  belongs_to :company
  validates_uniqueness_of :accession, scope: [:filed_at, :company_id]

  SEC_ARCHIVES_URL = "https://sec.gov/Archives/"

  def raw_path
    "edgar/data/#{company.cik.to_i}/#{accession}.txt"
  end

  def index_path
    "edgar/data/#{company.cik.to_i}/#{accession}-index.htm"
  end

  def excel_path
    "edgar/data/#{company.cik.to_i}/#{accession.gsub("-", '')}/Financial_Report.xlsx"
  end

  def url_for(symbol)
    URI.join(SEC_ARCHIVES_URL, send("#{symbol}_path")).to_s
  end

  def name
    "#{company.symbol} #{filed_at.year} #{company.name}"
  end

  # def parse
  #   update_attribute :processed_at, nil
  #   SecEdgar::ReportParser.new.perform self.id
  # end

  # def generate
  #   update_attribute :processed_at, nil
  #   file = "/tmp/html-report-#{self.id}.html"
  #   self.parse unless File.exists?(file)
  #   SecEdgar::ReportCreator.new.perform self.id, file
  # end

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
