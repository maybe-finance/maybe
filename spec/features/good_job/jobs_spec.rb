require 'rails_helper'

RSpec.describe "GoodJob Jobs Management", type: :feature do
  let(:user) { create(:user, :super_admin) }
  
  before do
    sign_in(user)
  end

  describe "handling locked jobs" do
    let!(:job) { create(:good_job_job) }

    scenario "attempting to view a locked job" do
      allow_any_instance_of(GoodJob::Job).to receive(:advisory_locked?).and_return(true)
      allow_any_instance_of(GoodJob::Job).to receive(:perform).and_raise(GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError)

      visit good_job_job_path(job)

      expect(page).to have_content("This job is already being processed or locked.")
      expect(current_path).to eq(good_job_jobs_path)
    end

    scenario "attempting to retry a locked job" do
      allow_any_instance_of(GoodJob::Job).to receive(:retry!).and_raise(GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError)

      visit good_job_jobs_path
      click_link "Retry"

      expect(page).to have_content("This job is already being processed or locked.")
      expect(current_path).to eq(good_job_jobs_path)
    end
  end
end
