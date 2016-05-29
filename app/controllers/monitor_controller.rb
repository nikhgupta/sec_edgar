require 'sidekiq/api'

class MonitorController < ApplicationController
  before_action :set_stats,  only: [:status]
  before_action :set_queues, only: [:status]

  def status
    respond_to do |format|
      format.json { render json: { stats: @stats }.to_json }
    end
  end

  private

  def set_stats
    @stats = Sidekiq::Stats.new
    @stats = {
      enqueued: @stats.enqueued, queues: @stats.queues, failed: @stats.failed,
      retry: @stats.retry_size
    }
  end

  def set_queues
    @queues = %w(crawler lister parser creator).map do |q|
      Sidekiq::Queue.new "sec_edgar_#{q}"
    end
  end
end
