ActiveAdmin.register Report do
  actions :index
  config.sort_order = "processed_at_asc"

  index do
    column(:ticker){|r| r.company.symbol}
    column("CIK"){|r| r.company.cik}
    column("Company"){|r| r.company.name}
    column("Year", sortable: :filed_at){|r| r.filed_at.year}
    column :form_type
    column(:filing_date, sort: :filed_at){|r| r.filed_at.strftime("%d-%m-%Y")}
    column(:pdf){ |r| link_to "PDF", r.pdf_url if r.pdf_url? }
    column(:excel){ |r| link_to "Excel", r.excel_url if r.excel_url? }
    column :processed_at
  end

  filter :company
  filter :accession
  filter :form_type
  filter :filed_at, label: "Filed Between"
end
