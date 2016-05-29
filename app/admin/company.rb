ActiveAdmin.register Company do
  actions :index
  config.sort_order = "cik_asc"

  index do
    column "Ticker", :symbol
    column "CIK", :cik
    column :name
    column :listed
    column :industry
    column :sector
  end

  filter :cik, label: "CIK"
  filter :symbol, label: "Ticker"
  filter :name
  filter :listed
  filter :industry
  filter :sector
end
