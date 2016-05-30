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

      OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_NO_SSLv2
      OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_NO_SSLv3
      OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_NO_COMPRESSION

      response = HTTPClient::CLIENT.get(uri, follow_redirect: true)
      raise response.reason unless response.ok? || response.redirect?
      response.body
    end

    def get_node(url)
      Nokogiri::HTML get_html(url)
    end
  end
end
