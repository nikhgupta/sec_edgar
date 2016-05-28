require 'open-uri'
require 'nokogiri'

module SecEdgar
  class Base
    include Sidekiq::Worker
    SEC_ARCHIVES_URL = "https://www.sec.gov/Archives/"
    NASDAQ_LISTING_URL = "http://www.nasdaq.com/screening/companies-by-industry.aspx"
    SEC_SEARCH_URL = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&type=10-K&dateb=&owner=exclude&count=100"

    private

    def read_csv(text, options = {})
      options.merge!(headers: true, header_converters: :symbol, converters: :all)
      CSV.parse text, options
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

    def get_node(url)
      Nokogiri::HTML get_html(url)
    end
  end
end
