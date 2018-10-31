require 'net/http'
require 'openssl'
require 'puppet/util/network_device/simple/device'
require 'cgi'
require 'algosec-sdk'

module Puppet::Util::NetworkDevice::Algosec
  # The main connection class to a AlgoSec's APIs
  class Device < Puppet::Util::NetworkDevice::Simple::Device
    def config
      raise Puppet::ResourceError, 'Could not find host in the configuration' unless super.key?('host')
      raise Puppet::ResourceError, 'The port attribute in the configuration is not an integer' if super.key?('port') && super['port'] !~ %r{\A[0-9]+\Z}
      raise Puppet::ResourceError, 'Could not find user/password in the configuration' unless super.key?('user') && super.key?('password')
      raise Puppet::ResourceError, 'ssl_enabled option in configuration is optional and must be boolean if it exists' unless !super.key?('ssl_enabled') || [true, false].include?(super['ssl_enabled'])
      super
    end

    def api
      return @api if @api
      @api = ALGOSEC_SDK::Client.new(config)
      @api.login
      @api
    end
  end
end
