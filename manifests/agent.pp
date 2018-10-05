# @summary
#   This resource manages the `resource_api::agent` and the algosec-sdk gem on an agent.
#
# @example
#   include algosec::agent
class algosec::agent {
  include resource_api::agent
  package { 'algosec-sdk':
    ensure   => present,
    provider => 'puppet_gem',
  }
}
