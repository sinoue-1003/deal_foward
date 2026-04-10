module Api
  class TasksController < BaseController
    # GET /api/tasks
    def index
      tasks = Task.includes(:deal, :company, :contact, :assigned_to).order(due_at: :asc)
      tasks = tasks.where(deal_id: params[:deal_id])       if params[:deal_id].present?
      tasks = tasks.where(status: params[:status])          if params[:status].present?
      tasks = tasks.where(task_type: params[:task_type])    if params[:task_type].present?
      tasks = tasks.where(assigned_to_id: params[:assigned_to_id]) if params[:assigned_to_id].present?
      tasks = tasks.overdue   if params[:overdue] == "true"
      tasks = tasks.due_today if params[:due_today] == "true"
      render json: tasks.map { |t| task_summary(t) }
    end

    # GET /api/tasks/:id
    def show
      render json: Task.find(params[:id])
    end

    # POST /api/tasks
    def create
      render json: Task.create!(task_params), status: :created
    end

    # PATCH /api/tasks/:id
    def update
      task = Task.find(params[:id])
      task.update!(task_params)
      render json: task
    end

    # DELETE /api/tasks/:id
    def destroy
      Task.find(params[:id]).destroy
      head :no_content
    end

    private

    def task_summary(task)
      task.as_json(only: %i[
        id title task_type status priority
        due_at completed_at created_at
      ]).merge(
        assigned_to_name: task.assigned_to&.name,
        deal_title:       task.deal&.title,
        contact_name:     task.contact&.full_name
      )
    end

    def task_params
      params.permit(
        :title, :description, :task_type, :status, :priority,
        :deal_id, :company_id, :contact_id, :playbook_step_id,
        :assigned_to_id, :created_by, :due_at, :reminder_at,
        :completed_at, :outcome
      )
    end
  end
end
