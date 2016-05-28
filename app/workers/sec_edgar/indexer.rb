module SecEdgar
  class Indexer < Base
    BASE_URL = "https://www.sec.gov/Archives/edgar/daily-index/"

    def perform(path)
      url  = "#{BASE_URL}#{path}"
      html = get_html(url)
      data = html.gsub(/(^.*?\n\n+|\n-+)/mi, "").strip
      data = convert_to_csv(data, col_sep: "|")
      data = data.select{ |row| row[:form_type] =~ /^10-K/ }
      data = data.map{|row| add_report_to_database(row)}.compact
      data.each{|report| SecEdgar::Reporter.perform_async report.id}
    end

    def add_report_to_database(row)
      try_count = 0

      company = Company.find_by(cin: row[:cin])
      identifier = File.basename(row[:file_name], ".txt")
      scope = company.reports.where(identifier: identifier)

      return scope.first if scope.exists?

      company.name << row[:company_name] unless company.name.include?(row[:company_name])
      report = company.reports.create form_type: row[:form_type],
        filed_at: Time.parse(row[:date_filed]), identifier: identifier
      company.save

      report
    rescue ActiveRecord::RecordNotUnique
      try_count += 1
      retry if try_count < 4
      nil
    end
  end
end
