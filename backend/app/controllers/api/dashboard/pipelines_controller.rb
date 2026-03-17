module Api
  module Dashboard
    class PipelinesController < Api::BaseController
      STAGES = %w[prospect qualify demo proposal negotiation closed_won closed_lost].freeze

      def show
        stage_data = STAGES.map do |stage|
          deals = Deal.where(stage: stage)
          {
            stage: stage,
            count: deals.count,
            total_amount: deals.sum(:amount).to_f,
            avg_probability: deals.average(:probability).to_f.round
          }
        end

        active_playbooks = Playbook.where(status: "active").includes(:company).limit(5).map { |pb|
          pb.as_json.merge(
            company_name: pb.company&.name,
            status_summary: pb.status_summary
          )
        }

        render json: {
          by_stage: stage_data,
          active_playbooks: active_playbooks
        }
      end
    end
  end
end
