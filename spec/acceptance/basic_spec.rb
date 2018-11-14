require 'spec_helper_acceptance'

describe 'basic algosec config' do
  let(:common_args) { '--detailed-exitcodes --verbose --debug --trace --strict=error --libdir lib --modulepath spec/fixtures/modules --deviceconfig spec/fixtures/acceptance-device.conf --target sut' }

  let(:result) do
    puts "Executing `puppet device #{common_args} #{args}`" if debug_output?
    Open3.capture2e("puppet device #{common_args} #{args}")
  end
  let(:stdout_str) { result[0] }
  let(:status) { result[1] }

  let(:args) { '--apply spec/fixtures/create.pp' }
  let(:application_name) { 'puppet-test-application' }

  context 'when creating resources' do
    let(:create_app_regex) { "Creating '#{application_name}' with {:name=>\"#{application_name}\", :ensure=>\"present\"}" }
    let(:create_app_flow1) { "Creating application flow '#{application_name}/flow with no optional fields defined'" }
    let(:create_app_flow2) { "Creating application flow '#{application_name}/flow with the application defined in the title'" }

    it 'applies a catalog with changes' do
      expect(stdout_str).not_to match %r{Error:}

      expect(stdout_str).to match create_app_regex
      expect(stdout_str).to match create_app_flow1
      expect(stdout_str).to match create_app_flow2
      puts stdout_str if debug_output?
      # See https://tickets.puppetlabs.com/browse/PUP-9067 "`puppet device` should respect --detailed-exitcodes"
      # expect(status.exitstatus).to eq 2
    end

    context 'when running an idempotency check' do
      it 'applies a catalog without changes' do
        expect(stdout_str).not_to match %r{Error:}
        # See https://tickets.puppetlabs.com/browse/PUP-9067 "`puppet device` should respect --detailed-exitcodes"
        # expect(status.exitstatus).to eq 0
      end

      context 'when applying a change' do
        let(:args) { '--apply spec/fixtures/update.pp' }
        let(:update_app_flow1) { "Updating application flow '#{application_name}/flow with no optional fields defined'" }
        let(:update_app_flow2) { "Updating application flow '#{application_name}/flow with the application defined in the title'" }

        it 'applies a catalog with changes' do
          expect(stdout_str).not_to match %r{Error:}
          expect(stdout_str).to match update_app_flow1
          expect(stdout_str).to match update_app_flow2
          puts stdout_str if debug_output?
          # See https://tickets.puppetlabs.com/browse/PUP-9067 "`puppet device` should respect --detailed-exitcodes"
          # expect(status.exitstatus).to eq 2
        end

        context 'when removing resources' do
          let(:args) { '--apply spec/fixtures/autodelete_flows.pp' }
          let(:delete_app_flow1) { "Deleting application flow 'puppet-test-application/flow with no optional fields defined'" }
          let(:delete_app_flow2) { "Deleting application flow 'puppet-test-application/flow with the application defined in the title'" }

          it 'applies a catalog with changes' do
            expect(stdout_str).not_to match %r{Error:}
            expect(stdout_str).to match delete_app_flow1
            expect(stdout_str).to match delete_app_flow2
            puts stdout_str if debug_output?
            # See https://tickets.puppetlabs.com/browse/PUP-9067 "`puppet device` should respect --detailed-exitcodes"
            # expect(status.exitstatus).to eq 2
          end

          context 'when applying the application draft' do
            let(:args) { '--apply spec/fixtures/apply_application_draft.pp' }
            let(:application_draft_applied) { 'Notice: algosec_apply_draft\[apply\]: Updating: Finished' }

            it 'applies a catalog with changes' do
              expect(stdout_str).not_to match %r{Error:}
              expect(stdout_str).to match application_draft_applied
              puts stdout_str if debug_output?
              # See https://tickets.puppetlabs.com/browse/PUP-9067 "`puppet device` should respect --detailed-exitcodes"
              # expect(status.exitstatus).to eq 2
            end
          end
        end
      end
    end
  end
end
