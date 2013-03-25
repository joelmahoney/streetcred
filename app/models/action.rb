class Action
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :user
  belongs_to :channel, :foreign_key => 'api_key', :primary_key => 'api_key'
  has_and_belongs_to_many :awards, dependent: :nullify, index: true
  
  
  field :api_key, type: String
  field :record_id, type: String # provider UID
  field :case_id, type: String
  field :action_type, type: String
  field :description, type: String
  field :shared, type: Boolean
  field :location, type: String
  field :latitude, type: BigDecimal
  field :longitude, type: BigDecimal
  field :url, type: String
  field :photo_url, type: String

  after_create :assign_awards
  
  # this callback assigns incoming actions to relevant awards, and assigns awards to users if the award's 
  # requirements have been met
  def assign_awards
    user = self.user
    # find awards that are in-range and match the action_type and channel of the incoming action
    matching_awards = Award.elem_match(required_actions: {name: self.action_type}).in(channel_ids: [self.channel.try(:id)]).lt(start_time: self.created_at).gt(end_time: self.created_at)
    
    # iterate through the matching awards and determine whether their requirements have been met
    matching_awards.each do |award|
      unless user.awards.include?(award)
        # assign the action to the award in order to track progress
        award.actions << self
        
        if award.requirements_met?(user)
          user.awards << award
        end
      end
    end
  end
end
