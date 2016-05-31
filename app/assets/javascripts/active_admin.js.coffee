#= require active_admin/base

updateProgressBar = ->
  remain = $(".status-area  .counter").text() * 1
  proced = $(".dropbox-area .counter").text() * 1
  return if remain is 0 or proced is 0
  percent = Math.round(proced / (remain + proced) * 100)
  return unless percent > 0
  $(".progress-bar div span").html("#{percent}%")
  $(".progress-bar div").css("background-color": "#696").animate width: "#{percent}%"

updateStats = ->
  $.get "/monitor/status.json", (response) ->
    console.log response
    html  = "<tr><td>Script has started?</td><td>#{if response.stats.enqueued > 0 then "Yes" else "No"}</td></tr>"
    html += "<tr><td>Getting listing from NASDAQ or done?</td><td>#{if response.stats.queues.sec_edgar_lister > 0 then "Fetching.." else "Done!"}</td></tr>"
    html += "<tr><td>Total Companies I found from NASDAQ listings</td><td>#{response.companies || 0}</td></tr>"
    html += "<tr><td>Companies where I need to find filings for</td><td>#{response.stats.queues.sec_edgar_crawler || 0}</td></tr>"
    html += "<tr><td>Filings where I need to generate report for</td><td class='counter'>#{response.stats.queues.sec_edgar_parser || 0}</td></tr>"

    method = if response.stats.enqueued > 0 then 'slideUp' else 'slideDown'
    $('.message-area')[method]()
    $("#queue-progress .status-area").html(html)
    updateProgressBar()

updateDropboxStats = ->
  $.get '/monitor/dropbox.json', (response) ->
    console.log response
    html  = "<tr><td>Total PDFs in Dropbox</td><td class='counter'>#{response.pdf_count || 0}</td></tr>"
    html += "<tr><td>Total Excel Sheets in Dropbox</td><td>#{response.xls_count || 0}</td></tr>"
    html += "<tr><td>Total Size of Reports in Dropbox</td><td>#{response.total_size || 0}</td></tr>"
    $("#dropbox-progress .dropbox-area").html(html)
    updateProgressBar()

ready = ->
  if $("#queue-progress").length > 0
    updateStats(); updateDropboxStats(); updateProgressBar()
    setInterval (-> updateStats()), 2000
    setInterval (-> updateDropboxStats()), 30000

$(document).ready(ready)
