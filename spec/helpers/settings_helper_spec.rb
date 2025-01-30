require 'rails_helper'

RSpec.describe SettingsHelper, type: :helper do
  describe '#adjacent_setting' do
    before do
      allow(helper).to receive(:self_hosted?).and_return(false)
    end

    it 'returns the correct path for invitations setting' do
      allow(helper).to receive(:invitations_path).and_return('/invitations')
      current_path = helper.invitations_path
      
      allow(helper).to receive(:render).and_return('rendered_content')
      result = helper.adjacent_setting(current_path, 1)
      
      expect(result).to eq('rendered_content')
    end

    it 'returns nil when there is no adjacent setting' do
      allow(helper).to receive(:settings_profile_path).and_return('/settings/profile')
      result = helper.adjacent_setting(helper.settings_profile_path, -1)
      expect(result).to be_nil
    end

    it 'handles conditional settings correctly' do
      allow(helper).to receive(:self_hosted?).and_return(true)
      allow(helper).to receive(:settings_hosting_path).and_return('/settings/hosting')
      
      result = helper.adjacent_setting(helper.settings_hosting_path, 0)
      expect(result).not_to be_nil
    end
  end

  describe '#settings_section' do
    it 'renders a settings section with title and content' do
      allow(helper).to receive(:render).and_return('rendered_section')
      result = helper.settings_section(title: 'Test Section') { 'content' }
      expect(result).to eq('rendered_section')
    end
  end
end
