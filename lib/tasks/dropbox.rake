require 'dropbox_sdk'

namespace :dropbox do
  desc "Authenticate dropbox for Uploading files"
  task authorize: :environment do
    session = DropboxSession.new(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])
    puts "Please, open this URL and grant access: #{session.get_authorize_url}"
    puts "Press ENTER when done"
    STDIN.gets.strip

    client = DropboxClient.new(session, "dropbox")
    begin
      info = client.account_info
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
end
