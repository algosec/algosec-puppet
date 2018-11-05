require 'puppet/resource_api/simple_provider'

# Implementation for the abf_flow type using the Resource API.
class Puppet::Provider::AbfFlow::AbfFlow < Puppet::ResourceApi::SimpleProvider
  def get(context)
    context.notice('Getting all application flows')

    # For each available application
    context.device.api.get_applications.map { |app_json|
      if context.device.managed_application?(app_json['name'])
        get_application_flows(context, app_json)
      else
        nil
      end
    }.compact.flatten
  end

  def create(context, name_hash, should)
    raise Puppet::ResourceError, "Creation cancelled for flow of an unmanaged application: #{name_from_hash(name_hash)}" unless context.device.managed_application?(name_hash[:application])
    context.notice("Creating application flow '#{name_from_hash(name_hash)}' with #{should.inspect}")
    # validate_should(should)
    app_revision_id = context.device.api.get_app_revision_id_by_name(name_hash[:application])
    context.device.api.create_application_flow(
      app_revision_id,
      name_hash[:name],
      should[:sources],
      should[:destinations],
      should.fetch(:services, []),
      should.fetch(:users, []),
      should.fetch(:applications, []),
      should.fetch(:comment, ''),
    )
  end

  def update(context, name_hash, should)
    raise Puppet::ResourceError, "Update cancelled for flow of an unmanaged application: #{name_from_hash(name_hash)}" unless context.device.managed_application?(name_hash[:application])
    # Currently PUT is not implemented for flows so we simply delete and re-create
    context.notice("Updating application flow '#{name_from_hash(name_hash)}' with #{should.inspect}")
    # validate_should(should)
    delete(context, name_hash)
    create(context, name_hash, should)
  end

  def delete(context, name_hash)
    raise Puppet::ResourceError, "Deletion cancelled for flow of an unmanaged application: #{name_from_hash(name_hash)}" unless context.device.managed_application?(name_hash[:application])
    context.notice("Deleting application flow '#{name_from_hash(name_hash)}'")
    app_revision_id = context.device.api.get_app_revision_id_by_name(name_hash[:application])
    flow_id = context.device.api.get_application_flow_by_name(app_revision_id, name_hash[:name])['flowID']
    context.device.api.delete_flow_by_id(app_revision_id, flow_id)
  end

  private

  def get_application_flows(context, app_json)
    # Convert the API flow into the flow as it is expected by puppet
    context.device.api.get_application_flows(app_json['revisionID']).map { |flow_json|
      # Skip non application flows
      if flow_json['flowType'] != 'APPLICATION_FLOW'
        nil
      else
        # First fetch all the required fields
        flow = {
          ensure: 'present',
          name: flow_json['name'],
          application: app_json['name'],
          sources: flow_json['sources'].map { |source| source['name'] },
          destinations: flow_json['destinations'].map { |dest| dest['name'] },
          services: flow_json['services'].map { |service| service['name'] },
          comment: flow_json.fetch('comment', ''),
          users: [],
          applications: [],
        }
        # Now populate the optional fields
        if flow_json['networkUsers']
          flow[:users] = (flow_json['networkUsers'].map { |user| user['name'] if user['id'] != 0 }).compact
        end

        if flow_json['networkApplications']
          flow[:applications] = (flow_json['networkApplications'].map { |app| app['name'] if app['revisionID'] != 0 }).compact
        end
        flow
      end
      # Use .compact to remove all flows that were filtered out
    }.compact
  end

  def name_from_hash(name_hash)
    "#{name_hash[:application]}/#{name_hash[:name]}"
  end
end
