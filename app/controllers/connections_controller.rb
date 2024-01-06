class ConnectionsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Connections where source is not manual
    @connections = current_family.connections.where.not(source: :manual)
  end

  def destroy
    @connection = current_family.connections.find(params[:id])
    @connection.destroy

    GenerateMetricsJob.perform(current_family.id)

    redirect_to connections_path
  end
end
