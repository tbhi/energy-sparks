module Admin
  class IssuesController < AdminController
    include Pagy::Backend
    before_action :header_fix_enabled

    load_and_authorize_resource :school, instance_name: 'issueable'
    load_and_authorize_resource :school_group, instance_name: 'issueable'
    load_and_authorize_resource :issue, through: :issueable, shallow: true

    def index
      params[:issue_types] ||= Issue.issue_types.keys
      list
    end

    def filter
      list
    end

    def new
      @issue = Issue.new(issue_type: params[:issue_type], issueable: @issueable)
    end

    def create
      @issue.attributes = { created_by: current_user, updated_by: current_user }
      if @issue.save
        redirect_to params[:previous_request], notice: issueable_notice('was successfully created')
      else
        render :new
      end
    end

    def update
      if @issue.update(issue_params.merge(updated_by: current_user))
        redirect_to params[:previous_request], notice: issueable_notice('was successfully updated')
      else
        render :edit
      end
    end

    def destroy
      @issue.destroy
      redirect_back_or_index notice: 'was successfully deleted'
    end

    def resolve
      notice = "was successfully resolved"
      unless @issue.resolve!(updated_by: current_user)
        notice = "Can only resolve issues (and not notes)."
      end
      redirect_back_or_index notice: notice
    end

    private

    def list
      respond_to do |format|
        format.html do
          @issues = @issues.by_issue_types(params[:issue_types])
          @issues = @issues.by_owned_by(params[:user]) if params[:user]
          @pagy, @issues = pagy(@issues.by_priority_order)
          render :index
        end
        format.csv do
          @issues = @issueable.all_issues if @issueable && @issueable.is_a?(SchoolGroup)
          send_data @issues.issue.status_open.by_updated_at.to_csv,
          filename: "#{t('common.application')}-issues-#{Time.zone.now.iso8601}".parameterize + '.csv'
        end
      end
    end

    def redirect_index(notice:)
      redirect_to issueable_index_url, notice: issueable_notice(notice)
    end

    def redirect_back_or_index(notice:)
      redirect_back fallback_location: issueable_index_url, notice: issueable_notice(notice)
    end

    def issueable_index_url
      @issue.issueable ? polymorphic_url([:admin, @issue.issueable, Issue]) : polymorphic_url([:admin, Issue])
    end

    def issueable_notice(notice)
      [@issue.issueable.try(:model_name).try(:human), @issue.issue_type, notice].compact.join(" ").capitalize
    end

    def issue_params
      params.require(:issue).permit(:issue_type, :title, :description, :fuel_type, :status, :owned_by_id, :pinned)
    end
  end
end
