require 'spec_helper'
require 'support/matchers/one_of'

ensure_module_defined('Puppet::Provider::AbfApplication')
require 'puppet/provider/abf_application/abf_application'

RSpec.describe Puppet::Provider::AbfApplication::AbfApplication do
  subject(:provider) { described_class.new }
  let(:unmanaged_applications) { [] }
  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:device) { instance_double('Puppet::Util::NetworkDevice::Algosec::Device', 'device') }
  let(:api) { instance_double('ALGOSEC_SDK::Client', 'api') }

  before(:each) do
    allow(context).to receive(:device).with(no_args).and_return(device)
    allow(device).to receive(:api).with(no_args).and_return(api)
    allow(device).to receive(:managed_application?).and_return(true)
    allow(device).to receive(:managed_application?).with(one_of(unmanaged_applications)).and_return(false)
    allow(context).to receive(:notice)
  end

  describe '#get(context)' do
    let(:application_names) { ['app1', 'app2'] }
    let(:applications_json) { application_names.map { |name| { 'name' => name } } }

    before(:each) do
      allow(api).to receive(:get_applications).with(no_args).and_return(applications_json)
    end

    it 'log a notice' do
      expect(context).to receive(:notice).with('Get all ABF Applications')
      provider.get(context)
    end
    it 'fetch managed applications from api' do
      expect(provider.get(context)).to eq [{ name: 'app1' }, { name: 'app2' }]
    end
    context 'when an application is not managed' do
      let(:unmanaged_applications) { ['app2'] }

      it "doesn't return it" do
        expect(provider.get(context)).to eq [{ name: 'app1' }]
      end
    end
  end

  describe '#create(context, name, should)' do
    let(:app_name) { 'app1' }

    before(:each) do
      allow(api).to receive(:create_application)
    end

    it 'log a notice' do
      expect(context).to receive(:notice).with(%r{\ACreating '#{app_name}'})
      provider.create(context, app_name, name: app_name, ensure: 'present')
    end
    it 'uses the api to create the app' do
      expect(api).to receive(:create_application).with(app_name).and_return('name' => app_name)
      provider.create(context, app_name, name: app_name, ensure: 'present')
    end
    context 'when an application is not managed' do
      let(:unmanaged_applications) { ['app2'] }
      it 'refuses to create it' do
        expect { provider.create(context, 'app2', name: 'app2') }.to raise_error("Creation cancelled for unmanaged application app2")
      end
    end
  end

  describe '#update(context, name, should)' do
    it 'raises an unimplemented exception' do
      expect { provider.update(context, 'app', name: 'app') }.to raise_error("#{provider.class} has not implemented `update`")
    end
  end

  describe '#delete(context, name, should)' do
    let(:app_name) { 'app1' }
    let(:app_revision_id) { 9999 }

    before(:each) do
      allow(api).to receive(:get_app_revision_id_by_name)
      allow(api).to receive(:decommission_application)
    end

    it 'log a notice' do
      expect(context).to receive(:notice).with(%r{\ADecommissioning '#{app_name}'})
      provider.delete(context, app_name)
    end

    it 'decommissions the application' do
      expect(api).to receive(:get_app_revision_id_by_name).with(app_name).and_return(app_revision_id)
      expect(api).to receive(:decommission_application).with(app_revision_id)
      provider.delete(context, app_name)
    end

    context 'when an application is not managed' do
      let(:unmanaged_applications) { [app_name] }
      it 'refuses to delete it' do
        expect { provider.delete(context, app_name) }.to raise_error("Deletion cancelled for unmanaged application #{app_name}")
      end
    end
  end
end
