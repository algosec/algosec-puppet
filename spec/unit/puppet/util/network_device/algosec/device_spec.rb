require 'spec_helper'
require 'puppet/util/network_device/algosec/device'

RSpec.describe Puppet::Util::NetworkDevice::Algosec do
  describe Puppet::Util::NetworkDevice::Algosec::Device do
    let(:device) { described_class.new(device_config) }
    let(:device_config) { { 'host' => 'www.example.com', 'user' => 'foo', 'password' => 'password', 'managed_applications' => managed_applications } }
    let(:managed_applications) { [] }

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
      context 'when no `managed_applicaions` provided in the config' do
        let(:device_config) { { 'host' => 'www.example.com', 'user' => 'foo', 'password' => 'password' } }

        it { expect { device.config }.not_to raise_error Puppet::ResourceError }
      end
      context 'when valid `managed_applications` are provided' do
        let(:managed_applications) { ['app1', 'app2'] }

        it { expect { device.config }.not_to raise_error Puppet::ResourceError }
      end
      context 'when invalid `managed_applications` are provided' do
        [
          'app1,app2,app3',
          [1, 2, 3],
          123456,
          { 'some' => 'object' },
        ].each do |managed_applications|
          let(:managed_applications) { managed_applications }

          it { expect { device.config }.to raise_error Puppet::ResourceError, 'Provided managed applications must be an array of strings if it exists' }
        end
      end
    end

    describe '#managed_application?' do
      context 'when `managed_applications` config is not defined' do
        let(:device_config) { { 'host' => 'www.example.com', 'user' => 'foo', 'password' => 'password' } }

        it 'returns true for any application name' do
          expect(device.managed_application?('app1')).to eq(true)
        end
      end
      context 'when `managed_applications` config is set to empty array' do
        let(:managed_applications) { [] }

        it 'returns true for any application name' do
          expect(device.managed_application?('app1')).to eq(true)
        end
      end
      context 'when `managed_applications` are defined' do
        let(:managed_applications) { ['app1', 'app2'] }

        it 'returns true for applications in the list' do
          expect(device.managed_application?('app1')).to eq(true)
        end
        it 'returns false for applications not in the list' do
          expect(device.managed_application?('app3')).to eq(false)
        end
      end
    end

    context 'when the algosec api client is mocked' do
      let(:api) { instance_double('ALGOSEC_SDK::Client', 'api') }

      before(:each) do
        allow(ALGOSEC_SDK::Client).to receive(:new).with(device.config).and_return(api)
        allow(api).to receive(:login)
      end

      describe '#api' do
        it 'login before first usage call' do
          expect(api).to receive(:login).with(no_args)
          device.api
        end
        it 'login only once per instance' do
          expect(api).to receive(:login).once.with(no_args)
          device.api
          device.api
        end
        it 'returns same client instance on consecutive calls' do
          expect(device.api).to eq(device.api)
        end
      end
      describe '#outstanding_drafts?' do
        let(:draft_app_json) do
          ->(app_name) do
            {
              'revisionID' => 368,
              'name' => app_name,
              'revisionStatus' => 'Draft',
            }
          end
        end
        let(:active_app_json) do
          ->(app_name) do
            {
              'revisionID' => 369,
              'name' => app_name,
              'revisionStatus' => 'Active',
            }
          end
        end
        it 'returns true when there are outstanding drafts' do
          expect(api).to receive(:get_applications).and_return([draft_app_json['app1'], active_app_json['app2']])
          expect(device.outstanding_drafts?).to eq true
        end
        it 'returns false when there are outstanding drafts' do
          expect(api).to receive(:get_applications).and_return([active_app_json['app1'], active_app_json['app2']])
          expect(device.outstanding_drafts?).to eq false
        end
        context 'when there are drafts only in non managed applications' do
          let(:managed_applications) { ['active-app'] }

          it 'returns false' do
            expect(api).to receive(:get_applications).and_return([draft_app_json['draft-app'], active_app_json['active-app']])
            expect(device.outstanding_drafts?).to eq false
          end
        end
      end
      describe '#apply_application_drafts' do
        let(:draft_app_json) do
          ->(app_name) do
            {
              'revisionID' => 368,
              'name' => app_name,
              'revisionStatus' => 'Draft',
            }
          end
        end
        let(:active_app_json) do
          ->(app_name) do
            {
              'revisionID' => 369,
              'name' => app_name,
              'revisionStatus' => 'Active',
            }
          end
        end
        it 'applies draft only when a draft is outstanding' do
          expect(api).to receive(:get_applications).and_return([draft_app_json['app1'], active_app_json['app2']])
          expect(api).to receive(:apply_application_draft).once.with(368)

          device.apply_application_drafts
        end
        context 'when there are drafts only in non managed applications' do
          let(:managed_applications) { ['active-app'] }

          it 'does not apply any' do
            expect(api).to receive(:get_applications).and_return([draft_app_json['draft-app'], active_app_json['active-app']])
            expect(api).not_to receive(:apply_application_draft)

            device.apply_application_drafts
          end
        end
      end
    end
  end
end
