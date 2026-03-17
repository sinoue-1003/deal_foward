module Api
  class PlaybooksController < BaseController
    # GET /api/playbooks
    def index
      playbooks = Playbook.includes(:company, :contact)
        .order(created_at: :desc)

      playbooks = playbooks.where(status: params[:status]) if params[:status].present?

      render json: playbooks.map { |pb|
        pb.as_json.merge(
          company_name: pb.company&.name,
          contact_name: pb.contact&.name,
          status_summary: pb.status_summary,
          total_steps: pb.steps.size,
          completed_steps: pb.steps.count { |s| s["status"] == "completed" }
        )
      }
    end

    # GET /api/playbooks/:id
    def show
      pb = Playbook.find(params[:id])
      executions = pb.playbook_executions.order(executed_at: :desc)

      render json: pb.as_json.merge(
        company: pb.company,
        contact: pb.contact,
        status_summary: pb.status_summary,
        executions: executions,
        total_steps: pb.steps.size,
        completed_steps: pb.steps.count { |s| s["status"] == "completed" }
      )
    end

    # GET /api/playbooks/:id/status
    # Shared AI+human status view: current situation + next actions
    def status
      pb = Playbook.find(params[:id])
      render json: {
        id: pb.id,
        title: pb.title,
        status: pb.status,
        situation_summary: pb.situation_summary,
        objective: pb.objective,
        status_summary: pb.status_summary,
        steps: pb.steps,
        current_step: pb.current_step,
        next_action: pb.next_action,
        company: pb.company&.as_json(only: [:id, :name]),
        contact: pb.contact&.as_json(only: [:id, :name, :role])
      }
    end

    # POST /api/playbooks
    def create
      pb = Playbook.create!(playbook_params)
      render json: pb, status: :created
    end

    # PATCH /api/playbooks/:id
    def update
      pb = Playbook.find(params[:id])
      pb.update!(playbook_params)
      render json: pb
    end

    # POST /api/playbooks/:id/execute
    # Manually execute the next step (by human)
    def execute
      pb = Playbook.find(params[:id])
      step = pb.next_action
      return render json: { message: "No pending steps" }, status: :unprocessable_entity unless step

      idx = pb.steps.index(step)
      steps = pb.steps.dup
      steps[idx] = steps[idx].merge(
        "status" => "completed",
        "executed_by" => "human",
        "completed_at" => Time.current.iso8601,
        "result" => params[:result] || "手動実行完了"
      )

      new_current = steps.index { |s| s["status"] == "pending" } || pb.current_step
      pb.update!(steps: steps, current_step: new_current)

      PlaybookExecution.create!(
        playbook: pb, step_index: idx,
        status: "completed", result: params[:result] || "手動実行完了",
        executed_by: "human", executed_at: Time.current
      )

      render json: pb.as_json.merge(status_summary: pb.status_summary)
    end

    private

    def playbook_params
      params.permit(:title, :status, :objective, :situation_summary, :company_id, :contact_id, :created_by, steps: [])
    end
  end
end
