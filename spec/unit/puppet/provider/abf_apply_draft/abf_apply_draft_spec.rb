require 'spec_helper'

ensure_module_defined('Puppet::Provider::AbfApplyDraft')
require 'puppet/provider/abf_apply_draft/abf_apply_draft'

RSpec.describe Puppet::Provider::AbfApplyDraft::AbfApplyDraft do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }
  let(:device) { instance_double('Puppet::Util::NetworkDevice::Algosec::Device', 'device') }

  before(:each) do
    allow(context).to receive(:device).with(no_args).and_return(device)
    allow(device).to receive(:outstanding_drafts?).and_return(outstanding_drafts)
  end

  describe '#get' do
    context 'when there are outstanding drafts' do
      let(:outstanding_drafts) { true }

      it do
        expect(provider.get(context)).to eq [
                                              {
                                                name: 'apply',
                                                apply: false,
                                              },
                                            ]
      end
    end
    context 'when there are no outstanding drafts' do
      let(:outstanding_drafts) { false }

      it do
        expect(provider.get(context)).to eq [
                                              {
                                                name: 'apply',
                                                apply: true,
                                              },
                                            ]
      end
    end
  end

  describe 'set(context, changes)' do
    context 'when there are outstanding drafts' do
      let(:outstanding_drafts) { true }

      context 'when the user requested a apply' do
        it 'applies them' do
          allow(context).to receive(:updating).with('apply').and_yield
          expect(device).to receive(:apply_application_drafts)
          provider.set(context, 'apply' => { should: { apply: true } })
        end
      end

      context 'when the user did not request a apply' do
        it 'ignores them' do
          expect(context).to receive(:info).with('application drafts detected, but skipping apply as requested')
          expect(context).not_to receive(:updating).with('apply').and_yield
          expect(device).not_to receive(:apply_application_drafts)
          provider.set(context, 'apply' => { should: { apply: false } })
        end
      end
    end

    context 'when there are no outstanding drafts' do
      let(:outstanding_drafts) { false }

      it 'emits a debug message' do
        expect(context).to receive(:debug).with('no application drafts detected')
        provider.set(context, 'apply' => { should: { apply: false } })
      end
    end
  end
end
