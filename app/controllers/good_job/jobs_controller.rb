module GoodJob
  class JobsController < GoodJob::ApplicationController
    rescue_from GoodJob::AdvisoryLockable::RecordAlreadyAdvisoryLockedError, with: :handle_record_already_locked

    before_action :set_job, only: [:show, :destroy, :discard, :retry, :reschedule]
    after_action :enable_polling, only: [:index]

    def index
      @jobs = Job.all
      @jobs = @jobs.where(active_job_id: params[:active_job_id]) if params[:active_job_id].present?
      @jobs = @jobs.where(queue_name: params[:queue_name]) if params[:queue_name].present?
      @jobs = @jobs.includes_advisory_locks
      
      respond_to do |format|
        format.html
        format.json { render json: @jobs }
      end
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: @job }
      end
    end

    def destroy
      @job.destroy
      respond_to do |format|
        format.html { redirect_to good_job_jobs_path, notice: "Job was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    def discard
      @job.discard!
      respond_to do |format|
        format.html { redirect_to good_job_jobs_path, notice: "Job was successfully discarded." }
        format.json { head :no_content }
      end
    end

    def retry
      @job.retry!
      respond_to do |format|
        format.html { redirect_to good_job_jobs_path, notice: "Job was successfully retried." }
        format.json { head :no_content }
      end
    end

    def reschedule
      @job.reschedule!
      respond_to do |format|
        format.html { redirect_to good_job_jobs_path, notice: "Job was successfully rescheduled." }
        format.json { head :no_content }
      end
    end

    private

    def set_job
      @job = Job.find(params[:id])
    end

    def enable_polling
      @polling_enabled = true
    end

    def handle_record_already_locked
      respond_to do |format|
        format.html { 
          flash[:alert] = "This job is already being processed or locked."
          redirect_to good_job_jobs_path
        }
        format.json { 
          render json: { error: "Job is locked" }, status: :conflict 
        }
      end
    end
  end
end
