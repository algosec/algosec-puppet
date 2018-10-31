require 'spec_helper'

ensure_module_defined('Puppet::Provider::AbfFlow')
require 'puppet/provider/abf_flow/abf_flow'

RSpec.describe Puppet::Provider::AbfFlow::AbfFlow do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:device) { instance_double('Puppet::Util::NetworkDevice::Panos::Device', 'device') }
  let(:api) { instance_double('ALGOSEC_SDK::Client', 'api') }

  let(:name) { 'flow-name' }
  let(:app_name) { 'application-name' }
  let(:app_revision_id) { 8888 }

  # Since abf_flow type has two namevars, it's name is passed as a hash that include all namevars
  let(:name_hash) { { name: name, application: app_name } }

  before(:each) do
    allow(context).to receive(:device).with(no_args).and_return(device)
    allow(device).to receive(:api).with(no_args).and_return(api)
    allow(context).to receive(:notice)
  end

  describe '#get(context)' do
    let(:app_name2) { 'application-name2' }
    let(:app_revision_id2) { 1232456 }

    # define the application json as it will be returned from the API.
    let(:app_json1) { { 'revisionID' => app_revision_id, 'name' => app_name } }
    let(:app_json2) { { 'revisionID' => app_revision_id2, 'name' => app_name2 } }

    # JSON Objects that mimics the original API json results returned from the API
    let(:flow_json_with_no_users_applications) do
      # This flow represent a possible ABF setting were the applications and users will not be present in the
      # response JSON
      {
        'flowID' => 1394,
        'name' => 'flow1',
        'comment' => 'comment1',
        'flowType' => 'APPLICATION_FLOW',
        'sources' => [
          { 'name' => '192.168.0.0/16' },
          { 'name' => 'HR Payroll server' }
        ],
        'destinations' => [{ 'name' => '16.47.71.62' }],
        'services' => [{ 'name' => 'HTTPS' }, 'name' => 'HTTP'],
      }
    end
    let(:flow_json_with_any_users_applications) do
      # This flow have the applications and users, but they were not set, so they appear here as ANY
      {
        'flowID' => 1394,
        'name' => 'flow1',
        'comment' => 'comment1',
        'flowType' => 'APPLICATION_FLOW',
        'sources' => [
          { 'name' => '192.168.0.0/16' },
          { 'name' => 'HR Payroll server' }
        ],
        'destinations' => [{ 'name' => '16.47.71.62' }],
        'services' => [{ 'name' => 'HTTPS' }, 'name' => 'HTTP'],
        'networkApplications' => [{ 'revisionID' => 0, 'name' => 'Any' }],
        'networkUsers' => [{ 'id' => 0, 'name' => 'Any' }],
      }
    end
    let(:flow_json_with_users_applications) do
      # This flow has the applications and users already defined to something
      {
        'flowID' => 1396,
        'name' => 'flow3',
        'comment' => 'comment3',
        'flowType' => 'APPLICATION_FLOW',
        'sources' => [{ 'name' => '10.0.0.1' }],
        'destinations' => [{ 'name' => '10.0.0.2' }],
        'services' => [{ 'name' => 'udp/501' }],
        'networkApplications' => [{ 'revisionID' => 5320, 'name' => 'Image Exchange' }],
        'networkUsers' => [{ 'id' => 1, 'name' => 'algosec user' }],
      }
    end
    let(:non_application_flow_json) do
      # This flow is not an APPLICATION_FLOW and therefore should not be included in the results
      {
        'flowID' => 1397,
        'name' => 'flow4',
        'comment' => '',
        'flowType' => 'SHARED_FLOW',
        'sources' => [{ 'name' => '10.0.0.1' }],
        'destinations' => [{ 'name' => '10.0.0.2' }],
        'services' => [{ 'name' => 'udp/501' }],
      }
    end

    # define the application flows as will be represented by the abf_flow provider per application
    let(:flow_with_no_users_applications) do
      -> (app_name) do
        return {
          name: 'flow1',
          application: app_name,
          sources: ['192.168.0.0/16', 'HR Payroll server'],
          destinations: ['16.47.71.62'],
          services: %w(HTTPS HTTP),
          users: [],
          applications: [],
          comment: 'comment1',
          ensure: 'present',
        }
      end
    end
    let(:flow_with_users_applications) do
      -> (app_name) do
        return {
          name: 'flow3',
          application: app_name,
          sources: ['10.0.0.1'],
          destinations: ['10.0.0.2'],
          services: ['udp/501'],
          users: ['algosec user'],
          applications: ['Image Exchange'],
          comment: 'comment3',
          ensure: 'present',
        }
      end
    end

    it 'logs an update notice' do
      allow(api).to receive(:get_applications).and_return([])
      allow(api).to receive(:get_application_flows)

      expect(context).to receive(:notice).with('Getting all application flows')
      provider.get(context)
    end

    context 'parses and filters api flows' do
      it 'filters out non application flows' do
        expect(api).to receive(:get_applications).with(no_args).and_return([app_json1])
        expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([non_application_flow_json])
        expect(provider.get(context)).to eq ([])
      end
      it 'handles missing users and applications fields' do
        expect(api).to receive(:get_applications).with(no_args).and_return([app_json1])
        expect(api).to receive(:get_application_flows).with(app_revision_id).and_return(
          [flow_json_with_no_users_applications]
        )
        expect(provider.get(context)).to eq ([flow_with_no_users_applications[app_name]])
      end
      it 'handles users and applications fields set as "any"' do
        expect(api).to receive(:get_applications).with(no_args).and_return([app_json1])
        expect(api).to receive(:get_application_flows).with(app_revision_id).and_return(
          [flow_json_with_any_users_applications]
        )
        # When the users and applications are set to any, it is same as if they were not defined at all
        expect(provider.get(context)).to eq ([flow_with_no_users_applications[app_name]])
      end
      it 'handles defined users and applications fields' do
        expect(api).to receive(:get_applications).with(no_args).and_return([app_json1])
        expect(api).to receive(:get_application_flows).with(app_revision_id).and_return(
          [flow_json_with_users_applications]
        )
        # When the users and applications are set to any, it is same as if they were not defined at all
        expect(provider.get(context)).to eq ([flow_with_users_applications[app_name]])
      end

      it 'fetch and combine flows from multiple apps' do
        expect(api).to receive(:get_applications).with(no_args).and_return([app_json1, app_json2])
        expect(api).to receive(:get_application_flows).with(app_revision_id).and_return(
          [flow_json_with_users_applications]
        )
        expect(api).to receive(:get_application_flows).with(app_revision_id2).and_return(
          [flow_json_with_no_users_applications]
        )
        # When the users and applications are set to any, it is same as if they were not defined at all
        expect(provider.get(context)).to eq ([
          flow_with_users_applications[app_name],
          flow_with_no_users_applications[app_name2],
        ])
      end
    end
  end

  describe 'create(context, name_hash, should)' do
    let(:should) do
      {
        sources: %w(source1, source2),
        destinations: %w(dest1, dest2),
        services: %w(service1, service2),
        users: %w(user1, user2),
        applications: %w(app1, app2),
        comment: 'some comment here'
      }
    end
    let(:required_only_should) do
      {
        sources: %w(source1, source2),
        destinations: %w(dest1, dest2),
        services: %w(service1, service2)
      }
    end
    before do
      allow(api).to receive(:get_app_revision_id_by_name)
      allow(api).to receive(:create_application_flow)
    end

    it 'logs an update notice' do
      expect(context).to receive(:notice).with(%r{\ACreating application flow '#{app_name}/#{name}'})
      provider.create(context, name_hash, should)
    end
    it 'creates the flow only if should is valid' do
      expect(api).to receive(:get_app_revision_id_by_name).with(app_name).and_return(app_revision_id)
      expect(api).to receive(:create_application_flow).with(
        app_revision_id,
        name,
        %w(source1, source2),
        %w(dest1, dest2),
        %w(service1, service2),
        %w(user1, user2),
        %w(app1, app2),
        'some comment here'
      )

      provider.create(context, name_hash, should)
    end
    it 'creates flow when no optional values given' do
      expect(api).to receive(:get_app_revision_id_by_name).with(app_name).and_return(app_revision_id)
      expect(api).to receive(:create_application_flow).with(
        app_revision_id,
        name,
        %w[source1, source2],
        %w[dest1, dest2],
        %w[service1, service2],
        [],
        [],
        ''
      )

      provider.create(context, name_hash, required_only_should)
    end
  end

  describe 'update(context, name_hash, should)' do
    let(:should) { { name: name, ensure: 'present' } }

    before do
      allow(provider).to receive(:delete)
      allow(provider).to receive(:create)
    end
    it 'logs a notice' do
      expect(context).to receive(:notice).with(%r{\AUpdating application flow '#{app_name}/#{name}'})
      provider.update(context, name_hash, should)
    end
    # it 'avoids deletion/creation if should is not valid' do
    #   expect(provider).to receive(:validate_should).with(should).and_raise(Puppet::ResourceError, 'should not valid')
    #   expect(provider).not_to receive(:delete)
    #   expect(provider).not_to receive(:create)
    #
    #   expect {provider.update(context, name_hash, should)}.to raise_error Puppet::ResourceError
    # end
    it 'uses delete and only then the create instance methods' do
      expect(provider).to receive(:delete).with(context, name_hash).ordered
      expect(provider).to receive(:create).with(context, name_hash, should).ordered

      provider.update(context, name_hash, should)
    end
  end

  describe 'delete(context, name_hash, should)' do
    let(:flow_id) { 999999 }

    before do
      allow(api).to receive(:get_app_revision_id_by_name)
      allow(api).to receive(:get_application_flow_by_name).and_return('flowID' => flow_id)
      allow(api).to receive(:delete_flow_by_id)
    end
    it 'logs a notice' do
      expect(context).to receive(:notice).with(%r{\ADeleting application flow '#{app_name}/#{name}'})
      provider.delete(context, name_hash)
    end
    it 'deletes the resource' do
      expect(api).to receive(:get_app_revision_id_by_name).with(app_name).and_return(app_revision_id)
      expect(api).to receive(:get_application_flow_by_name).with(app_revision_id, name).and_return(
        { 'flowID' => flow_id }
      )
      expect(api).to receive(:delete_flow_by_id).with(app_revision_id, flow_id)
      provider.delete(context, name_hash)
    end
  end
end
