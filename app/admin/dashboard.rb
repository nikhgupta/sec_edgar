require 'sidekiq/api'

ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  action_item :run, only: :index do
    unless Sidekiq::Stats.new.enqueued > 0
      link_to 'Run Script!', dashboard_run_script_path, method: :post
    end
  end

  page_action :run_script, method: :post do
    if Sidekiq::Stats.new.enqueued > 0
      message = { alert: "Script was not started. It seems that jobs are already in queue!" }
    else
      SecEdgar::Lister.perform_async
      message = { notice: "Script has been started. Please, make sure it has finished before doing this, again!" }
    end
    redirect_to dashboard_path, message
  end

  content title: proc{ I18n.t("active_admin.dashboard") } do

    div class: "support-area" do
      h3 { raw "For any support or help, please mail me at: <strong>me@nikhgupta.com</strong>, or Skype me at: <strong>nikh.gupta</strong>"}
    end

    div class: "progress", id: "queue-progress" do
      table do
        thead do
          tr do
            th(colspan: 2){ "Queue Backlogs" }
          end
        end
        tbody(class: "status-area") do
          tr do
            td(colspan: 2){ "Waiting..."}
          end
        end
      end
    end

    div class: "progress", id: "dropbox-progress" do
      div class: "progress progress-bar" do
        div do
          span "0%"
        end
      end

      table do
        thead do
          tr do
            th(colspan: 2){ "Dropbox Stats" }
          end
        end
        tbody(class: "dropbox-area") do
          tr do
            td(colspan: 2){ "Waiting..."}
          end
        end
      end

      small(style: "font-size: 10px") { "updated every few seconds.." }
    end

    div style: "clear: both"

    div class: "message-area" do
      link = link_to 'run the script', dashboard_run_script_path, method: :post
      raw "Seems like there are no enqueued jobs. You can #{link} now!"
    end

    hr

    div class: "empty-html-reports", style: "margin-top: 20px" do
      h3 "Empty HTML Reports (they will be queued again in the last)"
      ul(style: "columns: 3; -webkit-columns: 3; -moz-columns: 3") do
        raw Report.where(empty_html: true).map(&:name).sort_by(&:itself).map{|rn| "<li>#{rn}</li>"}.join
      end
    end
  end
end
