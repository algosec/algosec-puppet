require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'abf_flow',
  docs: <<-EOS,
This type provides Puppet with the capabilities to manage "Application Flows" on AlgoSec BusinessFlow.
The usage of this resources is dependent upon the resource deceleration of AlgoSec BusinessFlow Application.
Please see how-to-use examples and the abf_application resource.
  EOS
  features: ['remote_resource', 'canonicalize'],
  title_patterns: [
    {
      pattern: %r{^(?<application>.+)/(?<name>.+)$},
      desc: 'Where the flow name and the application name are provided with a slash separator',
    },
    {
      pattern: %r{^(?<name>.+)$},
      desc: 'Where only the flow name is given',
    },
  ],
  attributes: {
    name: {
      type: 'String',
      desc: 'The name of the application flow.',
      behaviour: :namevar,
    },
    application: {
      type: 'String',
      desc: 'The name of the application that the flow belongs to.',
      behaviour: :namevar,
    },
    sources: {
      type: 'Array[String[1],1]',
      desc: 'List of IPs or ABF network objects of traffic sources for the application flow.',
    },
    destinations: {
      type: 'Array[String[1],1]',
      desc: 'List of IPs or ABF network objects of traffic destinations for the application flow.',
    },
    services: {
      type: 'Array[String[1],1]',
      desc: <<DESC
List of traffic services to allow in the flow. Services can be as defined on AlgoSec
BusinessFlow or in a proto/port format (only UDP and TCP are supported as proto. e.g. tcp/50)
DESC
    },
    users: {
      type: 'Optional[Array[String[1]]]',
      desc: 'List of users which the application flow is relevant to.',
    },
    applications: {
      type: 'Optional[Array[String[1]]]',
      desc: 'List of network application names which the application flow is relevant to.',
    },
    comment: {
      type: 'Optional[String]',
      desc: 'Optional comment to attach to the flow.',
    },
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
  },
  autobefore: {
    abf_apply_draft: 'apply',
  },
)
