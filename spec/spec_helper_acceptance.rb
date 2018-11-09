require 'json'
require 'net/http'
require 'open3'

module Helpers
  def debug_output?
    ENV['ALGOSEC_TEST_DEBUG'] == 'true' || ENV['BEAKER_debug'] == 'true'
  end
end

RSpec.configure do |c|
  c.include Helpers
  c.extend Helpers

  c.before :suite do
    system('rake spec_prep')
    # system('env|sort')
    raise 'Could not locate or create a test host' unless ENV['ALGOSEC_TEST_HOST']
    @hostname = ENV['ALGOSEC_TEST_HOST']

    puts "Detected config for AlgoSec machine at: #{@hostname}"

    File.open('spec/fixtures/acceptance-credentials.conf', 'w') do |file|
      file.puts <<CREDENTIALS
host: #{@hostname}
user: #{ENV['ALGOSEC_TEST_USER'] || 'admin'}
password: #{ENV['ALGOSEC_TEST_PASSWORD'] || 'algosec'}
ssl_enabled: false
managed_applications: [ puppet-test-application ]
CREDENTIALS
    end

    File.open('spec/fixtures/acceptance-device.conf', 'w') do |file|
      file.puts <<DEVICE
[sut]
type algosec
url file://#{Dir.getwd}/spec/fixtures/acceptance-credentials.conf
DEVICE
    end
  end
end
