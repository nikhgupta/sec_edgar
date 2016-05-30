module SecEdgar
  class ReportCreator < Base
    sidekiq_options queue: :sec_edgar_reporter

    def perform(report_id, html_file)
      report = Report.includes(:company).find(report_id)
      return if report.processed?

      html      = File.read(html_file)
      pdf__file = "/tmp/#{report.name}.pdf"
      xlsx_file = "/tmp/#{report.name} - Financials.xlsx"

      pdf = WickedPdf.new.pdf_from_string html
      xls = get_html URI.join(SEC_ARCHIVES_URL, report.excel_path).to_s rescue nil

      report.add_dropbox_file :pdf,   pdf__file, pdf, true
      report.add_dropbox_file :excel, xlsx_file, xls, true if xls

      [pdf__file, html_file, xlsx_file].each{|f| FileUtils.rm_f f}
      report.processed_at  = Time.now
      report.save

      nil
    end
  end
end
