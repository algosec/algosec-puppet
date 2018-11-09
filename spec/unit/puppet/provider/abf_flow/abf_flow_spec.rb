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
  let(:full_flow_name) { "#{app_name}/#{name}" }
  let(:app_revision_id) { 888 }
  let(:unmanaged_applications) { [] }

  # Since abf_flow type has two namevars, it's name is passed as a hash that include all namevars
  let(:name_hash) { { name: name, application: app_name } }

  before(:each) do
    allow(context).to receive(:device).with(no_args).and_return(device)
    allow(device).to receive(:api).with(no_args).and_return(api)
    allow(device).to receive(:managed_application?).and_return(true)
    allow(device).to receive(:managed_application?).with(one_of(unmanaged_applications)).and_return(false)
    allow(context).to receive(:notice)
  end

  describe '#get(context)' do
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
          { 'name' => 'HR Payroll server' },
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
          { 'name' => 'HR Payroll server' },
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
    let(:unsorted_flow_json) do
      # This flow is used to demonstrate that list fields are sorted for idempotency purposes
      {
        'flowID' => 1396,
        'name' => 'flow',
        'comment' => 'comment',
        'flowType' => 'APPLICATION_FLOW',
        'sources' => [{ 'name' => 'source3' }, { 'name' => 'source2' }, { 'name' => 'source1' }],
        'destinations' => [{ 'name' => 'dest3' }, { 'name' => 'dest2' }, { 'name' => 'dest1' }],
        'services' => [{ 'name' => 'service3' }, { 'name' => 'service2' }, { 'name' => 'service1' }],
        'networkApplications' => [
          { 'revisionID' => 3, 'name' => 'app3' },
          { 'revisionID' => 2, 'name' => 'app2' },
          { 'revisionID' => 1, 'name' => 'app1' },
        ],
        'networkUsers' => [
          { 'id' => 3, 'name' => 'user3' },
          { 'id' => 2, 'name' => 'user2' },
          { 'id' => 1, 'name' => 'user1' },
        ],
      }
    end

    # define the application flows as will be represented by the abf_flow provider per application
    let(:flow_with_no_users_applications) do
      ->(app_name) do
        return {
          title: "#{app_name}/flow1",
          name: 'flow1',
          application: app_name,
          sources: ['192.168.0.0/16', 'HR Payroll server'],
          destinations: ['16.47.71.62'],
          services: ['HTTP', 'HTTPS'],
          users: [],
          applications: [],
          comment: 'comment1',
          ensure: 'present',
        }
      end
    end
    let(:flow_with_users_applications) do
      ->(app_name) do
        return {
          title: "#{app_name}/flow3",
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
    let(:flow_with_sorted_list_fields) do
      # This flow is used to demonstrate that list fields are sorted for idempotency purposes
      ->(app_name) do
        return {
          title: "#{app_name}/flow",
          name: 'flow',
          application: app_name,
          sources: ['source1', 'source2', 'source3'],
          destinations: ['dest1', 'dest2', 'dest3'],
          services: ['service1', 'service2', 'service3'],
          users: ['user1', 'user2', 'user3'],
          applications: ['app1', 'app2', 'app3'],
          comment: 'comment',
          ensure: 'present',
        }
      end
    end

    let(:app_name2) { 'application-name2' }
    let(:app_revision_id2) { 123 }

    let(:app_to_api_json) do
      {
        app_name => { 'revisionID' => app_revision_id, 'name' => app_name },
        app_name2 => { 'revisionID' => app_revision_id2, 'name' => app_name2 },
      }
    end
    # list of applications that would be returned from the server
    let(:applications) { [] }
    # define the application json as it will be returned from the API.
    let(:applications_json) { applications.map { |name| app_to_api_json[name] } }

    let(:flows_from_server) { provider.get(context) }

    before(:each) do
      allow(api).to receive(:get_applications).and_return(applications_json)
    end

    it 'logs an update notice' do
      allow(api).to receive(:get_application_flows)

      expect(context).to receive(:notice).with('Getting all application flows')
      flows_from_server
    end

    context 'parses and filters api flows' do
      context 'of one app' do
        let(:applications) { [app_name] }

        it 'filters out non application flows' do
          expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([non_application_flow_json])
          expect(flows_from_server).to eq []
        end
        it 'handles missing users and applications fields' do
          expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([flow_json_with_no_users_applications])
          expect(flows_from_server).to eq [flow_with_no_users_applications[app_name]]
        end
        it 'handles users and applications fields set as "any"' do
          expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([flow_json_with_any_users_applications])
          # When the users and applications are set to any, it is same as if they were not defined at all
          expect(flows_from_server).to eq [flow_with_no_users_applications[app_name]]
        end
        it 'handles defined users and applications fields' do
          expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([flow_json_with_users_applications])
          expect(flows_from_server).to eq [flow_with_users_applications[app_name]]
        end
        it 'sorts the list fields for idempotency reasons' do
          expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([unsorted_flow_json])
          expect(flows_from_server).to eq [flow_with_sorted_list_fields[app_name]]
        end
      end
      context 'of two apps' do
        let(:applications) { [app_name, app_name2] }

        it 'fetch and combine flows from multiple apps' do
          expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([flow_json_with_users_applications])
          expect(api).to receive(:get_application_flows).with(app_revision_id2).and_return([flow_json_with_no_users_applications])
          # When the users and applications are set to any, it is same as if they were not defined at all
          expect(flows_from_server).to eq [flow_with_users_applications[app_name], flow_with_no_users_applications[app_name2]]
        end
      end
    end
    context 'when an application is not managed' do
      let(:unmanaged_applications) { [app_name2] }
      let(:applications) { [app_name, app_name2] }

      it "doesn't return it's flows" do
        expect(api).to receive(:get_application_flows).with(app_revision_id).and_return([flow_json_with_users_applications])
        # The flows are returned only for the managed app
        expect(flows_from_server).to eq [flow_with_users_applications[app_name]]
      end
    end
  end

  describe '#create(context, name_hash, should)' do
    let(:should_hash) do
      {
        sources: ['source1', 'source2'],
        destinations: ['dest1', 'dest2'],
        services: ['service1', 'service2'],
        users: ['user1', 'user2'],
        applications: ['app1', 'app2'],
        comment: 'some comment here',
      }
    end
    let(:required_only_should) do
      {
        sources: ['source1', 'source2'],
        destinations: ['dest1', 'dest2'],
        services: ['service1', 'service2'],
      }
    end

    before(:each) do
      allow(api).to receive(:get_app_revision_id_by_name)
      allow(api).to receive(:create_application_flow)
    end

    it 'logs an update notice' do
      expect(context).to receive(:notice).with(%r{\ACreating application flow '#{app_name}/#{name}'})
      provider.create(context, name_hash, should_hash)
    end
    it 'creates the flow only if should is valid' do
      expect(api).to receive(:get_app_revision_id_by_name).with(app_name).and_return(app_revision_id)
      expect(api).to receive(:create_application_flow).with(
        app_revision_id,
        name,
        ['source1', 'source2'],
        ['dest1', 'dest2'],
        ['service1', 'service2'],
        ['user1', 'user2'],
        ['app1', 'app2'],
        'some comment here',
      )

      provider.create(context, name_hash, should_hash)
    end
    it 'creates flow when no optional values given' do
      expect(api).to receive(:get_app_revision_id_by_name).with(app_name).and_return(app_revision_id)
      expect(api).to receive(:create_application_flow).with(
        app_revision_id,
        name,
        ['source1', 'source2'],
        ['dest1', 'dest2'],
        ['service1', 'service2'],
        [],
        [],
        '',
      )

      provider.create(context, name_hash, required_only_should)
    end
    context 'when an application is not managed' do
      let(:unmanaged_applications) { [app_name] }

      it 'refuses creation of flows within it' do
        expect { provider.create(context, name_hash, should_hash) }.to raise_error("Creation cancelled for flow of an unmanaged application: `#{full_flow_name}`")
      end
    end
  end

  describe '#update(context, name_hash, should)' do
    let(:should_hash) { { name: name, ensure: 'present' } }

    before(:each) do
      allow(provider).to receive(:delete) # rubocop:disable RSpec/SubjectStub
      allow(provider).to receive(:create) # rubocop:disable RSpec/SubjectStub
    end
    it 'logs a notice' do
      expect(context).to receive(:notice).with(%r{\AUpdating application flow '#{app_name}/#{name}'})
      provider.update(context, name_hash, should_hash)
    end
    it 'uses delete and only then the create instance methods' do
      expect(provider).to receive(:delete).with(context, name_hash).ordered # rubocop:disable RSpec/SubjectStub
      expect(provider).to receive(:create).with(context, name_hash, should_hash).ordered # rubocop:disable RSpec/SubjectStub

      provider.update(context, name_hash, should_hash)
    end
    context 'when an application is not managed' do
      let(:unmanaged_applications) { [app_name] }

      it 'refuses update of any of its flows' do
        expect { provider.update(context, name_hash, should_hash) }.to raise_error("Update cancelled for flow of an unmanaged application: `#{full_flow_name}`")
      end
    end
  end

  describe '#delete(context, name_hash, should)' do
    let(:flow_id) { 999 }

    before(:each) do
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
      expect(api).to receive(:get_application_flow_by_name).with(app_revision_id, name).and_return('flowID' => flow_id)
      expect(api).to receive(:delete_flow_by_id).with(app_revision_id, flow_id)
      provider.delete(context, name_hash)
    end
    context 'when an application is not managed' do
      let(:unmanaged_applications) { [app_name] }

      it 'refuses deletion of any of its flows' do
        expect { provider.delete(context, name_hash) }.to raise_error("Deletion cancelled for flow of an unmanaged application: `#{full_flow_name}`")
      end
    end
  end
  describe '#canonicalize(context, resources)' do
    let(:abf_flow) do
      {
        name: 'flow',
        application: 'app_name',
        sources: ['4', '3', '2', '1'],
        destinations: ['4', '3', '2', '1'],
        services: ['4', '3', '2', '1'],
        users: ['4', '3', '2', '1'],
        applications: ['4', '3', '2', '1'],
        comment: 'comment',
        ensure: 'present',
      }
    end

    [:sources, :destinations, :services, :users, :applications].each do |list_attribute|
      it "sorts the `#{list_attribute}` attribute" do
        expect(provider.canonicalize(context, [abf_flow])[0][list_attribute]).to eq abf_flow[list_attribute].sort
      end
    end
    it 'does not fail due to an empty flow hash' do
      expect { provider.canonicalize(context, [{}]) }.not_to raise_error
    end
  end
end
