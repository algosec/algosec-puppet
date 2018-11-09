# bundle exec puppet device --modulepath spec/fixtures/modules/ --deviceconfig spec/fixtures/device.conf --target pavm --verbose --trace --apply spec/fixtures/apply_application_draft.pp

abf_apply_draft {
  'apply':
    apply => true
}