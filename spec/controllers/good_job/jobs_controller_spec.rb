require 'rails_helper'

RSpec.describe GoodJob::JobsController, type: :controller do
  let(:user) { create(:user, :super_admin) }
  
  before do
    sign_in(user)
  end

  describe "GET #show" do
    let(:job) { create(:good_job_job) }

    context "when the job is available" do
      it "returns successful response" do
        get :show, params: { id: job.id }
        expect(response).to be_successful
      end
    end

    context "when the job is already advisory locked" do
      before do
        allow_any_instance_of(GoodJob::Job).to receive(:advisory_locked?).and_return(true)
        allow_any_instance_of(GoodJob::Job).to receive(:perform).and_raise(GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError)
      end

      it "redirects with an alert message" do
        get :show, params: { id: job.id }
        expect(response).to redirect_to(good_job_jobs_path)
        expect(flash[:alert]).to eq("This job is already being processed or locked.")
      end

      it "returns conflict status for JSON requests" do
        get :show, params: { id: job.id }, format: :json
        expect(response).to have_http_status(:conflict)
        expect(JSON.parse(response.body)).to eq({ "error" => "Job is locked" })
      end
    end
  end

  describe "POST #retry" do
    let(:job) { create(:good_job_job) }

    context "when the job is already advisory locked" do
      before do
        allow_any_instance_of(GoodJob::Job).to receive(:retry!).and_raise(GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError)
      end

      it "redirects with an alert message" do
        post :retry, params: { id: job.id }
        expect(response).to redirect_to(good_job_jobs_path)
        expect(flash[:alert]).to eq("This job is already being processed or locked.")
      end

      it "returns conflict status for JSON requests" do
        post :retry, params: { id: job.id }, format: :json
        expect(response).to have_http_status(:conflict)
      end
    end
  end
end
