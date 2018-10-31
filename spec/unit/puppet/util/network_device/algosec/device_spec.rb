require 'spec_helper'
require 'puppet/util/network_device/algosec/device'

RSpec.describe Puppet::Util::NetworkDevice::Algosec do
  describe Puppet::Util::NetworkDevice::Algosec::Device do
    let(:device) { described_class.new(device_config) }
    let(:device_config) { { 'host' => 'www.example.com', 'user' => 'admin', 'password' => 'password' } }

    describe '#config' do
      context 'when host is not provided' do
        let(:device_config) { { 'user' => 'admin', 'password' => 'password' } }

        it { expect { device.config }.to raise_error Puppet::ResourceError, 'Could not find host in the configuration' }
      end
      context 'when port is provided but not valid' do
        let(:device_config) { { 'host' => 'www.example.com', 'port' => 'foo', 'user' => 'admin', 'password' => 'password' } }

        it { expect { device.config }.to raise_error Puppet::ResourceError, 'The port attribute in the configuration is not an integer' }
      end
      context 'when valid user credentials are not provided' do
        [
          { 'host' => 'www.example.com', 'user' => 'admin' },
          { 'host' => 'www.example.com', 'password' => 'password' },
          { 'host' => 'www.example.com' },
        ].each do |config|
          let(:device_config) { config }

          it { expect { device.config }.to raise_error Puppet::ResourceError, 'Could not find user/password in the configuration' }
        end
      end
      context 'when `user` and password is provided' do
        let(:device_config) { { 'host' => 'www.example.com', 'user' => 'foo', 'password' => 'password' } }

        it { expect { device.config }.not_to raise_error Puppet::ResourceError }
      end
    end

    describe '#api' do
      let(:api) { instance_double('ALGOSEC_SDK::Client', 'api') }

      before(:each) do
        allow(ALGOSEC_SDK::Client).to receive(:new).with(device.config).and_return(api)
      end
      it 'login before first usage call' do
        expect(api).to receive(:login).with(no_args)

        expect(device.api).to eq(api)
      end
      it 'login only once per instance' do

      end
      it 'returns same client instance on consecutive calls' do
        expect(api).to receive(:login).once.with(no_args)
        device.api
        device.api
      end
    end
  end
end
