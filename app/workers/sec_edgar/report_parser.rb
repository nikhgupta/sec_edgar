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

    def grab_body_for(doc, with_cover = true)
      body   = Nokogiri::HTML(doc[:text]).search("body").first.try(:inner_html)
      body ||= doc[:text]
      html   = "<div id='body-of-#{doc[:type]}' style='page-break-after:always'>#{body}</div>"
      return html unless with_cover
      "<div style='page-break-after:always;'>
        <h1 style='padding-top: 600px; text-align: center; font-size: 128px'>#{doc[:type]}</h1>
        </div>#{html}"
    end

    def merge_documents_for_reporting(report, documents)
      html = documents[1..-1].map{ |doc| grab_body_for(doc, true) }.join
      html = "#{grab_body_for(documents[0], false)}#{html}"
      "<html><head><title>#{report.name}</title></head><body>#{html}</body></html>"
    end

    def extract_info(node)
      keys = [:type, :description, :filename, :sequence]
      data = Hash[keys.map{|i| [i,node.match(/^<#{i}>(.*?)\n/i).try(:[],1)]}]

      return if !data[:type] || data[:type].downcase == "xml"
      return unless !data[:filename] || data[:filename] =~ /\.(html?|te?xt)$/

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

      # convert all other link tags with names to paragraphs
      node.search("a[name]").each do |tag|
        tag.name = "p"
        next unless tag.text.blank?
        tag.inner_html = "&nbsp;"
        tag.set_attribute "style", "float: left"
        tag.set_attribute "id", tag.attr("name")
      end

      # remove some extra formatting from the first page of the document
      node.search("body h5:first, hr[size='3'], body div:first hr[size='1']").remove()

      html = node.to_s

      # for older filings, which have a completely different format
      if node.search("page").any?
        html = html.gsub("<page>", "</pre><pre style='page-break-after:always'>")
        html = html.gsub(/<\/?(table|caption|s|c)>/, '')
        html = html.gsub(/^=+$/, '')
      end

      html
    end
  end
end
