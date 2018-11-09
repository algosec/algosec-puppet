
# Set AlgoSec BusinessFlow applications and flows to automatically purge unmanaged resources.
# resources { 'abf_application':
#     purge => true
# }

resources { 'abf_flow':
  purge => true
}