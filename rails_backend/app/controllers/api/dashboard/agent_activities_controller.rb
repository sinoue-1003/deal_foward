module Api
  module Dashboard
    class AgentActivitiesController < Api::BaseController
      def show
        reports = AgentReport.includes(:company, :contact)
          .order(created_at: :desc)
          .limit(10)

        render json: reports.map { |r|
          r.as_json.merge(
            company_name: r.company&.name,
            contact_name: r.contact&.name
          )
        }
      end
    end
  end
end
