require 'rails_helper'

RSpec.describe EventsController do
  describe '#parse_event_id' do
    it 'redirects to correct voting page when given an id' do
      event = create :event, user: create(:user)
      event.update_attributes(code: ("ABCD" + "#{event.id}"))
      get(:parse_event_id, {'controller' => 'events', 'action' => 'parse_event_id', 'unparsed_event_id' => event.code})
      expect(response).to redirect_to vote_event_path(event.id)
    end
  end
end