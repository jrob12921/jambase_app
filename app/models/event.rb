class Event < ActiveRecord::Base
  has_one :group_message
  has_many :user_events
  has_many :users, through: :user_events

  # This needs to changes

  def user_attending?(user)
    Event.where(jb_event_id: self.jb_event_id, user_id: user.id).present? ? true : false
  end
end
