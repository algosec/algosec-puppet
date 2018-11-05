require 'spec_helper'
require 'puppet/type/abf_apply_draft'

RSpec.describe 'the abf_apply_draft type' do
  it 'loads' do
    expect(Puppet::Type.type(:abf_apply_draft)).not_to be_nil
  end
end
