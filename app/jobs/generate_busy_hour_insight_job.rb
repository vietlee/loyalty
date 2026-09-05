class GenerateBusyHourInsightJob < ApplicationJob
  queue_as :default

  # matrix / busiest_slot are passed in (already aggregated, no raw rows) so the
  # job doesn't re-query; range is a {from:, to:} hash or nil.
  def perform(workspace_id, matrix, busiest_slot, range = nil)
    ws = Workspace.find_by(id: workspace_id) or return
    ActsAsTenant.with_tenant(ws) do
      matrix = symbolize_matrix(matrix)
      slot   = busiest_slot && busiest_slot.transform_keys(&:to_sym)
      BusyHourInsight.new(ws, matrix: matrix, busiest_slot: slot,
                          range: range&.transform_keys(&:to_sym)).generate!
    end
  rescue => e
    Rails.logger.error("[GenerateBusyHourInsightJob] #{e.class}: #{e.message}")
  end

  private

  # ActiveJob serializes hashes with string keys — restore the shape the
  # service/helpers expect ({ dow:, hours: }).
  def symbolize_matrix(matrix)
    Array(matrix).map { |r| { dow: (r["dow"] || r[:dow]).to_i, hours: Array(r["hours"] || r[:hours]) } }
  end
end
