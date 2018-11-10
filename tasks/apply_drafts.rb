#!/opt/puppetlabs/puppet/bin/ruby

# work around the fact that bolt (for now, see BOLT-132) is not able to transport additional code from the module
# this requires that the algosec module is pluginsynced to the node executing the task
require 'puppet'
Puppet.settings.initialize_app_defaults(
  Puppet::Settings.app_defaults_for_run_mode(
    Puppet::Util::RunMode[:agent],
  ),
)
$LOAD_PATH.unshift(Puppet[:plugindest])

# setup logging to stdout/stderr which will be available to task executors
Puppet::Util::Log.newdestination(:console)
Puppet[:log_level] = 'debug'

#### the real task ###

require 'json'
require 'puppet/util/network_device/algosec/device'

params = JSON.parse(ENV['PARAMS'] || STDIN.read)
device = Puppet::Util::NetworkDevice::Algosec::Device.new(params['credentials_file'])

if device.outstanding_drafts?
  device.apply_application_drafts
end
