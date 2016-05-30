require "uri"
require "net/https"
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
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)

      http.open_timeout = 30
      http.read_timeout = 30

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.ssl_version = :TLSv1_2
      http.ssl_timeout = 30

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      response.body
    end

    def get_node(url)
      Nokogiri::HTML get_html(url)
    end
  end
end
