#= require active_admin/base

updateStats = ->
  $.get "/monitor/status.json", (response) ->
    html  = "<tr><td>Total Jobs currently in Queue</td><td>#{response.stats.enqueued}</td></tr>"
    html += "<tr><td>Companies where Reports need to be searched</td><td>#{response.stats.queues.sec_edgar_crawler || 0}</td></tr>"
    html += "<tr><td>Reports which need to be parsed</td><td>#{response.stats.queues.sec_edgar_parser || 0}</td></tr>"
    html += "<tr><td>Reports which need to be converted</td><td>#{response.stats.queues.sec_edgar_reporter || 0}</td></tr>"

    method = if response.stats.enqueued > 0 then 'slideUp' else 'slideDown'
    $('#queue-progress .message-area')[method]()
    $("#queue-progress .ajaxed-area").html(html)

ready = ->
  if $("#queue-progress").length > 0
    setInterval (-> updateStats()), 5000

$(document).ready(ready)
