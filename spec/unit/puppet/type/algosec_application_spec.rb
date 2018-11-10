require 'spec_helper'
require 'puppet/type/algosec_application'

RSpec.describe 'the algosec_application type' do
  it 'loads' do
    expect(Puppet::Type.type(:algosec_application)).not_to be_nil
  end
end
