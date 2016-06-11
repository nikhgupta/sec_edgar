class Report < ActiveRecord::Base
  belongs_to :company, counter_cache: true
  validates_uniqueness_of :accession, scope: [:filed_at, :company_id]

  scope :processed, ->{ where("processed_at IS NOT NULL") }
  after_save :update_processed_counter_cache
  after_destroy :update_processed_counter_cache

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
    str = "#{company.symbol} #{filed_at.year} #{company.name}"
    return str if form_type.blank? || form_type == "10-K"
    "#{str} - #{form_type}"
  end

  def unprocessed?
    !processed?
  end

  def processed?
    processed_at.present?
  end

  def add_dropbox_file(name, tmp_path, data, overwrite = false)
    to_path = "/10k Automation/Annual Reports & Financials"
    to_path = "#{to_path}/#{File.basename(tmp_path)}"
    File.open(tmp_path, "wb"){|f| f << data}
    data = File.open(tmp_path){|f| Dropbox::CLIENT.put_file to_path, f, overwrite}
    data = Dropbox::CLIENT.shares(data["path"], false)
    uri  = URI.parse(data['url']); uri.query = nil
    update_attribute "#{name}_url", uri.to_s
  rescue DropboxError => e
    e.message =~ /failed to grab locks/i ? retry : raise
  end

  private

  def update_processed_counter_cache
    self.company.processed_count = self.company.reports.processed.count
    self.company.save
  end
end
