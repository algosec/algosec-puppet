require 'spec_helper'
require 'puppet/type/algosec_flow'

RSpec.describe 'the algosec_flow type' do
  it 'loads' do
    expect(Puppet::Type.type(:algosec_flow)).not_to be_nil
  end
end
