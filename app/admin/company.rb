ActiveAdmin.register Company do
  actions :index
  config.sort_order = "cik_asc"

  index do
    column "Ticker", :symbol
    column "CIK", :cik
    column :name
    column(:reports){|com| link_to "Reports", "/reports?q%5Bcompany_id_eq%5D=#{com.id}&order=filed_at_desc" if com.reports.any?}
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
