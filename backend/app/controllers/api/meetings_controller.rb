module Api
  class MeetingsController < BaseController
    # GET /api/meetings
    def index
      meetings = Meeting.includes(:deal, :company, :attendees).order(started_at: :desc)
      meetings = meetings.where(deal_id: params[:deal_id])       if params[:deal_id].present?
      meetings = meetings.where(status: params[:status])          if params[:status].present?
      meetings = meetings.where(meeting_type: params[:meeting_type]) if params[:meeting_type].present?
      render json: meetings.map { |m| meeting_summary(m) }
    end

    # GET /api/meetings/:id
    def show
      meeting = Meeting.includes(:attendees, :insight, :deal, :company).find(params[:id])
      render json: meeting.as_json.merge(
        attendees: meeting.attendees.map { |a|
          { id: a.id, name: a.display_name, email: a.email, attendee_type: a.attendee_type, attended: a.attended }
        },
        insight: meeting.insight,
        deal:    meeting.deal&.slice("id", "title", "stage"),
        company: meeting.company&.slice("id", "name")
      )
    end

    # POST /api/meetings
    def create
      meeting = Meeting.create!(meeting_params)
      render json: meeting, status: :created
    end

    # PATCH /api/meetings/:id
    def update
      meeting = Meeting.find(params[:id])
      meeting.update!(meeting_params)
      render json: meeting
    end

    # DELETE /api/meetings/:id
    def destroy
      Meeting.find(params[:id]).destroy
      head :no_content
    end

    private

    def meeting_summary(meeting)
      meeting.as_json(only: %i[
        id title meeting_type status
        started_at ended_at duration_minutes
        meeting_url recording_url created_at
      ]).merge(
        deal_title:      meeting.deal&.title,
        company_name:    meeting.company&.name,
        attendee_count:  meeting.attendees.size
      )
    end

    def meeting_params
      params.permit(
        :deal_id, :company_id, :title, :meeting_type, :status,
        :started_at, :ended_at, :duration_minutes,
        :meeting_url, :recording_url, :external_id
      )
    end
  end
end
