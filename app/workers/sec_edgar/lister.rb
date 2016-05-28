module SecEdgar
  class Lister < Base
    EXCHANGES_USED = ["NASDAQ", "NYSE"]

    def perform
      companies.each do |data|
        record = create_or_update_company(data)
        SecEdgar::Crawler.perform_async record.id
      end
    end

    protected

    def create_or_update_company(data)
      scope = Company.where(symbol: data[:symbol])
      return scope.first if scope.exists?

      Company.create(symbol: data[:symbol],
        name: data[:name], sector: data[:sector],
        industry: data[:industry], ipo_year: data[:ipoyear],
        last_sale: data[:lastsale], market_capital: data[:marketcap])
    end

    def companies
      data = EXCHANGES_USED.map do |ex|
        csv = read_csv(get_html(url_for(ex)))
        [ex, csv]
      end
      Hash[data].map{|k,v| v.map{|row| Hash[row]}}.flatten.uniq
    end

    def url_for(exchange)
      "#{NASDAQ_LISTING_URL}?exchange=#{exchange.to_s.camelize.upcase}&render=download"
    end
  end
end
