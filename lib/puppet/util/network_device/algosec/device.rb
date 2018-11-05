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
      raise Puppet::ResourceError, 'Provided managed applications must be an array of strings if it exists' unless
        !super.key?('managed_applications') || super['managed_applications'].all? { |x| x.is_a? String }
      super
    end

    def managed_application?(app_name)
      # all applications are managed if no applications set in config
      return true if config.fetch('managed_applications', []) == []
      config['managed_applications'].include?(app_name)
    end

    def outstanding_drafts?
      api.get_applications.each do |app_json|
        if managed_application?(app_json['name']) && app_json.fetch('revisionStatus') == 'Draft'
          Puppet::Util::Log.log_func("Outstanding application draft found for: #{app_json['name']}", :info, [])
          return true
        end
      end
      false
    end

    def apply_application_drafts
      api.get_applications.each do |app_json|
        if managed_application?(app_json['name']) && app_json.fetch('revisionStatus') == 'Draft'
          api.apply_application_draft(app_json['revisionID'])
          Puppet::Util::Log.log_func("Application draft applied for: #{app_json['name']}", :info, [])
        end
      end
      true
    end

    def api
      return @api if @api
      @api = ALGOSEC_SDK::Client.new(config)
      @api.login
      @api
    end
  end
end
