module Api
  module Agent
    class RunsController < Api::BaseController
      include AgentAuthentication

      # POST /api/agent/run
      def create
        company  = Company.find_by(id: params[:company_id])
        playbook = Playbook.find_by(id: params[:playbook_id]) if params[:playbook_id].present?

        run = AgentRun.create!(
          company:  company,
          playbook: playbook,
          trigger:  params[:trigger] || "manual",
          status:   "analyzing",
          messages: []
        )

        AgentRunJob.perform_later(run.id)

        render json: run_json(run), status: :created
      end

      # GET /api/agent/runs
      def index
        runs = AgentRun.recent.limit(50)
        render json: runs.map { |r| run_json(r) }
      end

      # GET /api/agent/runs/:id
      def show
        run = AgentRun.find(params[:id])
        render json: run_json(run)
      end

      # POST /api/agent/runs/:id/approve
      def approve
        run = AgentRun.find(params[:id])

        unless run.status == "waiting_approval"
          return render json: { error: "Run is not waiting for approval (status: #{run.status})" }, status: :unprocessable_entity
        end

        approved = params[:approved] != false && params[:approved].to_s != "false"
        comment  = params[:comment].to_s

        # Find the last request_human_approval tool_use id in messages
        approval_tool_use_id = find_pending_approval_tool_use_id(run.messages)

        if approval_tool_use_id
          # Append tool_result to resume the Claude conversation
          messages = run.messages.dup
          messages << {
            role:    "user",
            content: [
              {
                type:        "tool_result",
                tool_use_id: approval_tool_use_id,
                content:     { approved: approved, comment: comment }.to_json
              }
            ]
          }

          run.update!(
            status:           approved ? "executing" : "executing",
            pending_approval: nil,
            messages:         messages
          )
        else
          run.update!(status: "executing", pending_approval: nil)
        end

        AgentRunJob.perform_later(run.id)

        render json: run_json(run)
      end

      # POST /api/agent/runs/:id/reject
      def reject
        # reject is just approve with approved: false
        params[:approved] = false
        params[:comment]  = params[:reason] || "Rejected by human operator"
        approve
      end

      private

      def run_json(run)
        {
          id:               run.id,
          status:           run.status,
          trigger:          run.trigger,
          company_id:       run.company_id,
          company_name:     run.company&.name,
          playbook_id:      run.playbook_id,
          playbook_title:   run.playbook&.title,
          pending_approval: run.pending_approval,
          tool_calls_count: (run.tool_calls || []).size,
          error_message:    run.error_message,
          created_at:       run.created_at,
          updated_at:       run.updated_at
        }
      end

      def find_pending_approval_tool_use_id(messages)
        # Walk messages in reverse to find last request_human_approval tool_use block
        messages.reverse_each do |msg|
          next unless msg.is_a?(Hash) && msg["role"] == "assistant"

          content = msg["content"] || []
          content.reverse_each do |block|
            b = block.is_a?(Hash) ? block : {}
            if b["type"] == "tool_use" && b["name"] == "request_human_approval"
              return b["id"]
            end
          end
        end
        nil
      end
    end
  end
end
