require 'spec_helper'
require 'puppet/type/algosec_apply_draft'

RSpec.describe 'the algosec_apply_draft type' do
  it 'loads' do
    expect(Puppet::Type.type(:algosec_apply_draft)).not_to be_nil
  end
end
