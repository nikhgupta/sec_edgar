require 'open-uri'

module SecEdgar
  class ReportParser < Base
    sidekiq_options queue: :sec_edgar_parser

    def perform(report_id)
      report = Report.includes(:company).find(report_id)
      return if report.processed?

      docs = get_documents report
      docs = docs.map{ |doc| extract_info(doc)  }.compact
      html = merge_documents_for_reporting(report, docs)
      html = sanitize_html(html)
      file = "/tmp/html-report-#{report_id}.html"
      File.open(file, "wb"){|f| f << html}
      ReportCreator.perform_async report_id, file

      nil
    end

    protected

    def get_documents(report)
      url  = "#{SEC_ARCHIVES_URL}#{report.index_path}"
      node = Nokogiri::HTML get_html(url)
      docs = node.search(".tableFile a").map{|a| a.attr("href")}
      docs = docs.select{|a| a =~ /\.html?$/ }
      return docs.map{|a| get_html URI.join(SEC_ARCHIVES_URL, a).to_s } if docs.any?
      url  = "#{SEC_ARCHIVES_URL}#{report.raw_path}"
      html = get_html(url)
      html.split("<DOCUMENT>")
    end

    def merge_documents_for_reporting(report, documents)
      name = "#{report.company.symbol} #{report.filed_at.year} #{report.company.name}"
      html = documents.map do |doc|
        "<div style='page-break-after:always;'>
         <h1 style='padding-top: 600px; text-align: center; font-size: 128px'>#{doc[:type]}</h1>
         </div><div id='body-of-#{doc[:type]}' style='page-break-after:always;'>
        #{Nokogiri::HTML(doc[:text]).search("body").first.inner_html}</div>"
      end.join
      "<html><head><title>#{name}</title></head><body>#{html}</body></html>"
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
        p = a.ancestors("p").try :first
        next unless p
        p.set_attribute("id", a.attr("name").downcase)
        a.remove

        tags = p.search("a[name]")
        next if tags.count < 1

        tags.each do |tag|
          tag.remove
          node.search("[href='##{tag.attr('name').downcase}']").map do |x|
            x.set_attribute('href', "##{a.attr('name').downcase}")
          end
        end
      end

      # remove some extra formatting from the first page of the document
      node.search("body h5:first, hr[size='3'], body div:first hr[size='1']").remove()

      html = node.to_s

      if node.search("page").any?
        html = html.gsub("<page>", "</pre><pre style='page-break-after:always'>")
        html = html.gsub(/<\/?(table|caption|s|c)>/, '')
        html = html.gsub(/^=+$/, '')
      end

      html
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
