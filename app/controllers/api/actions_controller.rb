class Api::ActionsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  # before_filter :verify_api_token
  
  respond_to :json
  
  # generic create
  def create
    if params['email'].present?
      user = User.find_or_create_by(email: params['email'])
      action = user.actions.create(params['action'])
      @earned_awards = user.awards_earned_by_action(action)
      NotificationMailer.status_email(user, action).deliver
      respond_with(@earned_awards)
    end
  end
  
  def citizens_connect
    if Channel.where(api_key: params['api_key']).present?
      if params['user']['email'].present? || params['user']['contact_id'].present?
        if params['user']['email'].present?
          user = User.where(email: params['user']['email']).first_or_create
        elsif params['user']['contact_id'].present?
          user = User.where(contact_id: params['user']['contact_id']).first_or_create
        end
        user.update_attributes(params['user'])
        params['report']['api_key'] = params['api_key']
        action = user.actions.create(
          api_key: params['api_key'],
          record_id: params['report']['record_id'],
          case_id: params['report']['case_id'],
          event: params['report']['event'],
          action_type: params['report']['service'],
          description: params['report']['description'],
          shared: params['report']['shared'],
          latitude: params['report']['latitude'],
          longitude: params['report']['longitude'],
          url: params['report']['url'],
          image_url: params['report']['image_url'],
          timestamp: params['report']['timestamp']
        )
        @earned_awards = user.awards_earned_by_action(action)
        NotificationMailer.status_email(user, action).deliver
        respond_with(@earned_awards)
      else
        return "No user info supplied"
      end
    else
      return "Invalid api_key"
    end
  end
  
  private
  def verify_api_token
    # if Channel.where(api_key: params['api_key']).present?
  end
end
