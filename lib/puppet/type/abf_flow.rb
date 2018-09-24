require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'abf_flow',
  docs: <<-EOS,
      This type is only used to define the different application flows comprising one abf_application resource.
      The connectivity for each ABF application is defined by the sum effect of the list of application flows 
        that are defined within it. Please see the abf_application type for how-to-use documentation.
    EOS
  features: [],
  attributes:   {
    name:        {
      type:      'String',
      desc:      'The name of the application flow.',
      behaviour: :namevar,
    },
    sources:        {
      type:      'Array[String[1],1]',
      desc:      'List of IPs or ABF network objects of traffic sources for the application flow.',
    },
    destinations:        {
      type:      'Array[String[1],1]',
      desc:      'List of IPs or ABF network objects of traffic destinations for the application flow.',
    },
    services:        {
      type:      'Array[String[1],1]',
      desc:      'List of traffic services to allow in the flow. Services can be as defined on AlgoSec '\
                    'BusinessFlow or in a proto/port format (only UDP and TCP are supported as proto. e.g. tcp/50).',
    },
    users:        {
      type:      'Array[String[1]]',
      desc:      'List of users which the application flow is relevant to.',
    },
    applications:        {
      type:      'Array[String[1]]',
      desc:      'List of network application names which the application flow is relevant to.',
    },
    comment:        {
      type:      'Optional[String]',
      desc:      'Optional comment to attach to the flow.',
    },
  },
)
