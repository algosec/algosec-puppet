require 'spec_helper'
require 'puppet/type/abf_application'

RSpec.describe 'the abf_application type' do
  it 'loads' do
    expect(Puppet::Type.type(:abf_application)).not_to be_nil
  end
end
