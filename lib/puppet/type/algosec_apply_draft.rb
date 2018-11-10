require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'algosec_apply_draft',
  docs: <<-EOS,
@summary When evaluated, this resource apply all outstanding application drafts in the managed AlgoSec server.

@note If managed applications are defined in the device config, only their drafts will be applied.
@note It is automatically scheduled after all other AlgoSec BusinessFlow resources.
  EOS
  features: ['remote_resource'],
  attributes: {
    name: {
      type: 'Enum["apply"]',
      desc: 'The name of the resource you want to manage. Can only be "apply".',
      behaviour: :namevar,
    },
    apply: {
      type: 'Boolean',
      desc: 'Whether an `apply application draft`should happen',
      defaultto: false,
    },
  },
)
