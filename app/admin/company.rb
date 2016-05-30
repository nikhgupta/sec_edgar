ActiveAdmin.register Company do
  actions :index
  config.sort_order = "processed_count_desc"

  index do
    column "Ticker", :symbol
    column "CIK", :cik
    column :name
    column :listed
    column(:reports){|com| link_to "Reports", "/reports?q%5Bcompany_id_eq%5D=#{com.id}&order=filed_at_desc" if com.reports.any?}
    column "# Processed", :processed_count
    column("% Done") do |com|
      percent = (com.processed_count / com.reports_count.to_f * 100).round(2) if com.reports_count > 0
      raw "<div class='progress-bar' style='height: 10px'><div style='width: #{percent}%; height: 10px; background-color: #696; padding: 0'></div></div>" if percent
    end
    # column :industry
    column :sector
  end

  filter :cik, label: "CIK"
  filter :symbol, label: "Ticker"
  filter :name
  filter :listed
  filter :industry
  filter :sector
end
