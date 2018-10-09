require 'puppet/resource_api/simple_provider'

# Implementation for the abf_flow type using the Resource API.
class Puppet::Provider::AbfFlow::AbfFlow < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    context.notice("Creating '#{name}' with #{should.inspect}")
    validate_should(should) if defined? validate_should
    app_revision_id = context.device.api.get_app_revision_id_by_name(should['application'])
    context.device.api.create_application_flow(
      app_revision_id,
      name,
      should['sources'],
      should['destinations'],
      should.fetch('services', []),
      should.fetch('users', []),
      should.fetch('applications', []),
      should.fetch('comment', ''),
      )
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    validate_should(should) if defined? validate_should
    app_revision_id = context.device.api.get_app_revision_id_by_name(should['application'])
    context.device.api.create_application_flow(
      app_revision_id,
      name,
      should['sources'],
      should['destinations'],
      should.fetch('services', []),
      should.fetch('users', []),
      should.fetch('applications', []),
      should.fetch('comment', ''),
    )
  end

  def update(context, name, should)
    # Currently PUT is not implemented for flows so we simply delete and re-create
    delete(context, name)
    create(context, name, should)
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    app_revision_id = context.device.api.get_app_revision_id_by_name(should['application'])
    flow_id = context.device.api.get_application_flow_by_name(name)['flowID']
    context.device.api.delete_flow_by_id(app_revision_id, flow_id)
  end
end
