module SecEdgar
  class Crawler < Base
    def perform(company_id)
      company = Company.find company_id
      html = get_node("#{SEC_SEARCH_URL}&CIK=#{company.symbol}")

      # update CIK
      cik = html.search(".companyName a").text.gsub(/\(.*\)/, '').strip
      return company.update_attribute(:listed, false) if cik.blank?
      company.update_attribute :cik, cik

      # get filings for each year
      filings = html.search("#seriesDiv tr").map do |row|
        link = row.search("td a").try(:first).try(:attr, :href)
        next unless link =~ /\.html?$/
        type = row.search("td:eq(1)").try(:first).try(:text)
        date = row.search("td:eq(4)").try(:first).try(:text)
        { url: link, date: date, type: type }
      end.compact

      filings.map do |row|
        accession = File.basename(row[:url]).gsub(/-index.html?$/, '')
        report = company.reports.find_or_create_by accession: accession,
          filed_at: Time.parse(row[:date]), form_type: row[:type]

        SecEdgar::ReportParser.perform_async report.id if report.unprocessed?
      end
    end
  end
end
