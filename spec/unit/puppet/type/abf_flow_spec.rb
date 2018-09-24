require 'spec_helper'
require 'puppet/type/abf_flow'

RSpec.describe 'the abf_flow type' do
  it 'loads' do
    expect(Puppet::Type.type(:abf_flow)).not_to be_nil
  end
end
