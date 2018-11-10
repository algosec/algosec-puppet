
# Set AlgoSec BusinessFlow applications and flows to automatically purge unmanaged resources.
# resources { 'algosec_application':
#     purge => true
# }

resources { 'algosec_flow':
  purge => true
}