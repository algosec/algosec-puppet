# bundle exec puppet device --modulepath spec/fixtures/modules/ --deviceconfig spec/fixtures/device.conf --target pavm --verbose --trace --apply tests/test_commit.pp

# Set AlgoSec BusinessFlow applications and flows to automatically purge unmanaged resources.
resources { 'abf_application':
    purge => true
}

resources { 'abf_flow':
  purge => true
}

abf_apply_draft {
  'apply':
    apply => true
}