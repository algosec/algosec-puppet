require 'puppet/resource_api/simple_provider'

# Implementation for the abf_application type using the Resource API.
class Puppet::Provider::AbfApplication::AbfApplication < Puppet::ResourceApi::SimpleProvider
  def get(context)
    context.notice('Get all ABF Applications')
    applications = context.device.api.get_applications
    # Strip all keys but the application name
    applications.map do |application| {
      name: application['name'] } if context.device.managed_application?(application['name'])
    end.compact
  end

  def create(context, name, should)
    raise Puppet::ResourceError, "Creation cancelled for unmanaged application #{name}" unless context.device.managed_application?(name)
    context.notice("Creating '#{name}' with #{should.inspect}")
    # TODO: Support all of hte application attributes (other than name) when the AlgoSec ABF API implements PUT
    # TODO: for abf applications
    context.device.api.create_application(name)
  end

  # def update(context, name, should)
  #   # TODO: Not needed currently as the only attribute of applications is name.
  #   # TODO: This method will be implemented when ABF API will implement the PUT method for applications
  # end

  def delete(context, name)
    raise Puppet::ResourceError, "Deletion cancelled for unmanaged application #{name}" unless context.device.managed_application?(name)
    context.notice("Decommissioning '#{name}'")
    app_revision_id = context.device.api.get_app_revision_id_by_name(name)
    context.device.api.decommission_application(app_revision_id)
  end
end
