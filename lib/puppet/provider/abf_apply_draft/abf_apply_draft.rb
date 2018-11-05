require 'puppet/resource_api/simple_provider'

# Implementation for the abf_apply_draft type using the Resource API.
class Puppet::Provider::AbfApplyDraft::AbfApplyDraft < Puppet::ResourceApi::SimpleProvider
  def get(context)
    [
      {
        name: 'apply',
        # return a value that causes an update if the user requested one
        apply: !context.device.outstanding_drafts?,
      },
    ]
  end

  def set(context, changes)
    if context.device.outstanding_drafts?
      if changes['apply'][:should][:apply]
        context.updating('apply') do
          context.device.apply_application_drafts
        end
      else
        context.info('application drafts detected, but skipping apply as requested')
      end
    else
      context.debug('no application drafts detected')
    end
  end
end
