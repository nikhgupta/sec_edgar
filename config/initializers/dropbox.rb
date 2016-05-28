require 'dropbox_sdk'

# Because you need the session with the right access token, you need to create one instance per user
session = DropboxSession.new(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])
if ENV['DROPBOX_ACCESS_TOKEN'].present?
  session.set_access_token(ENV['DROPBOX_ACCESS_TOKEN'], ENV['DROPBOX_ACCESS_TOKEN_SECRET'])
  Dropbox::CLIENT = DropboxClient.new(session, :dropbox)
else
  puts "Please, open this URL and grant access: #{session.get_authorize_url}"
  puts "Press ENTER when done"
  STDIN.gets.strip

  Dropbox::CLIENT = DropboxClient.new(session, "dropbox")
  begin
    info = Dropbox::CLIENT.account_info
  rescue DropboxAuthError => e
    puts 'It seems that we were unable to authenticate you!'
    puts "Dropbox said: #{e.message}"
    exit 1
  end

  quota = info["quota_info"]["quota"] / 1024.0**3
  puts "Authenticated as: #{info['display_name']} with #{quota} GB quota!"

  token  = session.get_access_token.key
  secret = session.get_access_token.secret

  puts
  puts "You should add the following environment variables:"
  puts "export DROPBOX_ACCESS_TOKEN='#{token}'"
  puts "export DROPBOX_ACCESS_TOKEN_SECRET='#{secret}'"
end
