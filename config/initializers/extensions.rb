require 'openssl'
require 'resolv-replace'

pattern = Rails.root.join("lib", "extensions", "*.rb")
Dir.glob(pattern.to_s).each{|file| require file}
