module Api
  class SequencesController < BaseController
    # GET /api/sequences
    def index
      sequences = Sequence.includes(:steps, :enrollments).order(created_at: :desc)
      sequences = sequences.where(status: params[:status])               if params[:status].present?
      sequences = sequences.where(sequence_type: params[:sequence_type]) if params[:sequence_type].present?
      render json: sequences.map { |s|
        s.as_json.merge(
          step_count:       s.steps.size,
          enrollment_count: s.enrollments.active.size
        )
      }
    end

    # GET /api/sequences/:id
    def show
      sequence = Sequence.includes(:steps, :enrollments).find(params[:id])
      render json: sequence.as_json.merge(steps: sequence.steps)
    end

    # POST /api/sequences
    def create
      render json: Sequence.create!(sequence_params), status: :created
    end

    # PATCH /api/sequences/:id
    def update
      sequence = Sequence.find(params[:id])
      sequence.update!(sequence_params)
      render json: sequence
    end

    # POST /api/sequences/:id/enroll
    def enroll
      sequence = Sequence.find(params[:id])
      contact  = Contact.find(params[:contact_id])
      deal     = params[:deal_id].present? ? Deal.find(params[:deal_id]) : nil
      enrollment = sequence.enroll!(contact, deal: deal)
      render json: enrollment, status: :created
    end

    # DELETE /api/sequences/:id
    def destroy
      Sequence.find(params[:id]).destroy
      head :no_content
    end

    private

    def sequence_params
      params.permit(:name, :description, :status, :sequence_type, :target_stage, :created_by_id)
    end
  end
end
