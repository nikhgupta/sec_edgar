require 'open-uri'

module SecEdgar
  class ReportParser < Base
    include Sidekiq::Worker
    def perform(report_id)
      report    = Report.includes(:company).find(report_id)
      url       = "#{SEC_ARCHIVES_URL}#{report.raw_path}"
      html      = get_html(url)
      documents = html.split("<DOCUMENT>")
      documents = documents.map{ |doc| extract_info(doc)  }.compact
      html      = merge_documents_for_reporting(documents)
      html_file = "#{report.company.symbol} #{report.filed_at.year} #{report.company.name}.pdf"
      xlsx_file = "#{report.company.symbol} #{report.filed_at.year} #{report.company.name}_Financials.xlsx"

      create_pdf_report html, html_file
      download_financial_report report, xlsx_file

      report.update_attribute :processed_at, Time.now
    end

    protected

    # ensure that the filename is compliant
    def write_binary(file, data)
      File.open(file.to_s, "wb"){|f| f << data}
      file.to_s
    end

    def download_financial_report(report, file)
      url = URI.join(SEC_ARCHIVES_URL, report.excel_path).to_s
      write_binary file, open(url).read
    rescue OpenURI::HTTPError
    end

    def create_pdf_report(html, file)
      html = sanitize_html html
      write_binary file, WickedPdf.new.pdf_from_string(html)
    end

    def merge_documents_for_reporting(documents)
      html = documents.map do |doc|
        "<div style='page-break-after:always;'>
         <h1 style='padding-top: 600px; text-align: center; font-size: 128px'>#{doc[:type]}</h1>
         </div><div id='body-of-#{doc[:type]}' style='page-break-after:always;'>
        #{Nokogiri::HTML(doc[:text]).search("body").first.inner_html.strip}</div>"
      end.join
      "<html><head><title>SOME TITLE</title></head><body>#{html}</body></html>"
    end

    def extract_info(node)
      keys = [:type, :description, :filename, :sequence]
      data = Hash[keys.map{|i| [i,node.match(/^<#{i}>(.*?)\n/i).try(:[],1)]}]

      return if !data[:type] || data[:type].downcase == "xml"
      return unless data[:filename] =~ /\.(html?|te?xt)$/

      data[:text] = node.match(/^<text>(.*?)<\/text>/mi).try(:[],1)
      data
    end

    def sanitize_html(html)
      node = Nokogiri::HTML html

      # replace anchor names that conflict with page links in PDF
      node.search("p font a[name]").each do |a|
        p = a.parent.parent.parent rescue next
        p.set_attribute("id", a.attr("name"))
        a.remove

        tags = p.search("a[name]")
        next if tags.count < 1

        tags.each do |tag|
          tag.remove
          node.search("[href='##{tag.attr('name')}']").map do |x|
            x.set_attribute('href', "##{a.attr('name')}")
          end
        end
      end

      # remove some extra formatting from the first page of the document
      node.search("body h5:first, hr[size='3'], body div:first hr[size='1']").remove()

      # old filings have <page> tags to denote different pages
      html = node.to_s
      html = html.gsub("<page>", "</pre><pre style='page-break-after:always'>")
      html = html.gsub(/<\/?(table|caption|s|c)>/, '')
      html = html.gsub(/^=+$/, '')
      # node.search("page").each do |tag|
      #   tag.name = "br"
      #   tag.set_attribute "style", "page-break-after:always"
      # end
      html

      # node.to_s
    end

    def get_html(url)
      h = open(url)
      Zlib::GzipReader.new(h).read
    rescue Zlib::GzipFile::Error, Zlib::Error # Not gzipped
      h.rewind
      h.read
    ensure
      h.close if h
    end
  end
end
