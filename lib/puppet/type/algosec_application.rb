require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'algosec_application',
  docs: <<-EOS,
This type provides Puppet with the capabilities to manage Applications on AlgoSec BusinessFlow.
Currently the management capabilities of this resource are limited until proper update API methods are
implemented in AlgoSec BusinessFlow.
  EOS
  features: ['remote_resource'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this application should be present or absent on the target AlgoSec BusinessFlow.',
      default: 'present',
    },
    name: {
      type: 'String[2]',
      desc: 'The name of the AlgoSec BusinessFlow application.',
      behaviour: :namevar,
    },
  },
  autobefore: {
    algosec_apply_draft: 'apply',
  },
)
