module Api
  class PlaybooksController < BaseController
    # GET /api/playbooks
    def index
      playbooks = Playbook.includes(:company, :contact, :playbook_steps)
        .order(created_at: :desc)

      playbooks = playbooks.where(status: params[:status]) if params[:status].present?

      render json: playbooks.map { |pb|
        pb.as_json.merge(
          company_name: pb.company&.name,
          contact_name: pb.contact&.name,
          status_summary: pb.status_summary,
          total_steps: pb.playbook_steps.size,
          completed_steps: pb.playbook_steps.count { |s| s.status == "completed" }
        )
      }
    end

    # GET /api/playbooks/:id
    def show
      pb = Playbook.includes(:company, :contact, playbook_steps: :playbook_executions).find(params[:id])
      executions = pb.playbook_executions.order(executed_at: :desc)

      render json: pb.as_json.merge(
        company: pb.company,
        contact: pb.contact,
        status_summary: pb.status_summary,
        next_action: pb.next_action,
        playbook_steps: pb.playbook_steps.as_json(include: { playbook_executions: { only: %i[id status action_content result executed_by_id executed_at] } }),
        executions: executions,
        total_steps: pb.playbook_steps.size,
        completed_steps: pb.playbook_steps.count { |s| s.status == "completed" }
      )
    end

    # GET /api/playbooks/:id/status
    # Shared AI+human status view
    def status
      pb = Playbook.includes(:playbook_steps).find(params[:id])
      render json: {
        id: pb.id,
        title: pb.title,
        status: pb.status,
        situation_summary: pb.situation_summary,
        objective: pb.objective,
        status_summary: pb.status_summary,
        playbook_steps: pb.playbook_steps,
        next_action: pb.next_action,
        company: pb.company&.as_json(only: %i[id name]),
        contact: pb.contact&.as_json(only: %i[id first_name last_name position])
      }
    end

    # POST /api/playbooks
    def create
      pb = Playbook.create!(playbook_params)

      (params[:steps] || []).each_with_index do |step_data, i|
        pb.playbook_steps.create!(
          step_index: step_data[:step] || i + 1,
          action_type: step_data[:action_type],
          executor_type: step_data[:executor_type] || "ai",
          channel: step_data[:channel],
          target: step_data[:target],
          template: step_data[:template],
          due_in_hours: step_data[:due_in_hours],
          status: "pending"
        )
      end

      render json: pb.as_json.merge(playbook_steps: pb.playbook_steps), status: :created
    end

    # PATCH /api/playbooks/:id
    def update
      pb = Playbook.find(params[:id])
      pb.update!(playbook_params)
      render json: pb
    end

    # POST /api/playbooks/:id/execute
    # ステップを手動実行またはスキップ（人間による操作）
    # params: step_index (optional), skip (bool), result (string)
    def execute
      pb = Playbook.find(params[:id])
      is_skip = params[:skip].in?([ true, "true", "1" ])
      new_status = is_skip ? "skipped" : "completed"
      default_result = is_skip ? "スキップ" : "手動実行完了"

      step = if params[:step_index].present?
        s = pb.playbook_steps.find_by(step_index: params[:step_index].to_i)
        return render json: { error: "Step not found" }, status: :not_found unless s
        return render json: { error: "Step is not pending" }, status: :unprocessable_entity unless s.pending?
        s
      else
        s = pb.next_action
        return render json: { message: "No pending steps" }, status: :unprocessable_entity unless s
        s
      end

      step.update!(status: new_status, executed_by_id: Current.user&.id, completed_at: Time.current)

      PlaybookExecution.create!(
        playbook: pb,
        playbook_step: step,
        status: new_status,
        action_content: step.template,
        result: params[:result] || default_result,
        executed_by_id: Current.user&.id,
        executed_at: Time.current
      )

      pb.maybe_auto_complete!

      render json: pb.as_json.merge(
        status_summary: pb.status_summary,
        playbook_steps: pb.playbook_steps
      )
    end

    private

    def playbook_params
      params.permit(:title, :status, :objective, :situation_summary, :company_id, :contact_id, :created_by)
    end
  end
end
