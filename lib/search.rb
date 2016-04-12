class Search

  def search_artist_by_name(artist_name)

    artist_name.take_out_spaces!

    artist_search = HTTParty.get("http://api.jambase.com/artists?name=#{artist_name}&page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json", verify: false).parsed_response

    artist_names = []

    if artist_name.present?
      for i in 0...artist_search['Artists'].length
        artist = artist_search['Artists'][i]
        artist_names << {artist_id: artist['Id'], artist_name: artist['Name']}
      end
    end

    artist_names
  end

  def search_venue_by_name(venue_name)

    venue_name.take_out_spaces!

    venue_search = HTTParty.get("http://api.jambase.com/venues?name=#{venue_name}&page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json", verify: false).parsed_response

    venue_names = []

    if venue_name.present?
      for i in 0...venue_search['Venues'].length
        venue = venue_search['Venues'][i]
        venue_names << {venue_id: venue['Id'], venue_name: venue['Name']}
      end
    end

    venue_names
  end

  def search_venue_by_zipCode(venue_zipCode)

    venue_search = HTTParty.get("http://api.jambase.com/venues?zipCode=#{venue_zipCode}&page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json", verify: false).parsed_response

    venue_names = []

    if venue_zipCode.present?
      for i in 0...venue_search['Venues'].length
        venue = venue_search['Venues'][i]
        venue_names << {venue_id: venue['Id'], venue_name: venue['Name']}
      end
    end

    venue_names
  end

  def search_event_by_location_and_date(zipCode, radius, startDate, endDate)

    url = "http://api.jambase.com/events?"

    url += "zipCode=#{zipCode}&" if zipCode.present?

    url += "radius=#{radius}&" if radius.present?
    # yyyy-mm-dd
    url += "startDate=#{startDate}&" if startDate.present?

    url += "endDate=#{endDate}&" if endDate.present?

    url += "page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json"

    event_search = HTTParty.get(url, verify: false).parsed_response

    events = []

    if zipCode.present? || startDate.present?
      for i in 0...event_search['Events'].length
        event = event_search['Events'][i]
        # See if I can get venue_ID
        events << {event_id: event['Id'], event_date: event['Date'], event_venue: event['Venue'], event_artists: event['Artists'], event_url: event['TicketUrl']}
      end
    end

    events
  end

  def get_event_by_id(event_id)
    HTTParty.get("http://api.jambase.com/events?id=#{event_id}&api_key=#{ENV['JAMBASE_API_KEY']}", verify: false).parsed_response
    # Maybe create my own has to return?
  end

  def get_artist_events(artist_name, zipCode, radius, startDate, endDate)
    artist_id = ::Search.new.get_artist_id(artist_name)

    url = "http://api.jambase.com/events?"

    url += "artistId=#{artist_id}&"

    url += "zipCode=#{zipCode}&" if zipCode.present?

    url += "radius=#{radius}&" if radius.present?
    # yyyy-mm-dd
    url += "startDate=#{startDate}&" if startDate.present?

    url += "endDate=#{endDate}&" if endDate.present?

    url += "page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json"

    artist_events = HTTParty.get(url, verify: false).parsed_response

    events = []

    for i in 0...artist_events['Events'].length
      event = artist_events['Events'][i]
      # See if I can get venue ID...
      events << {event_id: event['Id'], event_date: event['Date'], event_venue: event['Venue'], event_artists: event['Artists'], event_url: event['TicketUrl']}
    end

    events
  end

  def get_venue_events(venue_name, startDate, endDate)
    venue_id = ::Search.new.get_venue_id(venue_name)
    
    url = "http://api.jambase.com/events?"

    url += "venueId=#{venue_id}&"
    # yyyy-mm-dd
    url += "startDate=#{startDate}&" if startDate.present?

    url += "endDate=#{endDate}&" if endDate.present?

    url += "page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json"

    venue_events = HTTParty.get(url, verify: false).parsed_response

    events = []

    for i in 0...venue_events['Events'].length
      event = venue_events['Events'][i]
      events << {event_id: event['Id'], event_date: event['Date'], event_venue: event['Venue'], event_artists: event['Artists'], event_url: event['TicketUrl']}
    end

    events
  end

  def get_artist_id(artist_name)
    artist_name.take_out_spaces!

    artist_search = HTTParty.get("http://api.jambase.com/artists?name=#{artist_name}&page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json", verify: false).parsed_response

    artist_search['Artists'][0]['Id']
    
  end

  def get_venue_id(venue_name)
    venue_name.take_out_spaces!

    venue_search = HTTParty.get("http://api.jambase.com/venues?name=#{venue_name}&page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json", verify: false).parsed_response

    venue_search['Venues'][0]['Id']
  end

  private

  def take_out_spaces!(input)
    input.gsub!(' ', '+')
  end

# inputs = {jb_artist_id: a, jb_venue_id: b, jb_event_id: c, zip_code: d, radius: e, start_date: f, end_date: g, artist_name: h, venue_name: i}
  def insert_into_url!(type, inputs={})  
    if type == "event"
      @url = "http://api.jambase.com/events?"

      if inputs['jb_event_id'].present? || inputs['jb_artist_id'].present?
        # In an event search, only event_id and artist_id can use zip_code and radius, not venue_id
        @url += "id=#{inputs['jb_event_id']}&" if inputs['jb_event_id'].present?
        @url += "artistId=#{inputs['jb_artist_id']}&" if inputs['jb_artist_id'].present?  
        @url += "zipCode=#{zip_code}&" if inputs['zip_code'].present?
        @url += "radius=#{radius}&" if inputs['radius'].present?
      
      elsif inputs['jb_venue_id'].present?
        @url += "venueId=#{inputs['jb_venue_id']}&"
      end

      # start_date and end_date can be used in all scenarios 
      # format is yyyy-mm-dd
      if inputs['start_date'].present?
        @url += "startDate=#{start_date}&" 
      # use end_date as the startDate if a user inputs end date instead of start date
      elsif !inputs['start_date'].present? && inputs['end_date'].present?
        @url += "startDate=#{end_date}"
      # end_date can only be used if start date is also used
      elsif inputs['end_date'].present? && inputs['start_date'].present?
        @url += "endDate=#{end_date}&"
      end

    elsif type == "artist"
      @url = "http://api.jambase.com/artist?"

      if inputs['jb_artist_id'].present?
        @url += "id=#{inputs['jb_artist_id']}&"

      elsif inputs['artist_name'].present?
        @url += "name=#{inputs['artist_name'].gsub!(' ', '+')}&"

      end

    elsif type == "venue"
      @url = "http://api.jambase.com/venues?"

      if inputs['jb_venue_id'].present?
        @url += "id=#{inputs['jb_venue_id']}&"  
      elsif inputs['venue_name'].present?
        @url += "name=#{inputs['venue_name'].gsub!(' ', '+')}&"
      elsif inputs['zip_code'].present?
        @url += "zipCode=#{zip_code}&"
      end
    end

    # Randomly Generate API KEY from list of active keys
    # This should be removed once API Key has more calls and 
    api_keys = [
        ENV['JAMBASE_API_KEY']
        # ,ENV['JAMBASE_2'],
        # ,ENV['JAMBASE_3'],
        # ,ENV['JAMBASE_4'],
        # ,ENV['JAMBASE_5']
      ]

    @url += "page=0&api_key=#{api_keys.sample}&o=json" # "page=0&api_key=#{ENV['JAMBASE_API_KEY']}&o=json"

    response = HTTParty.get(@url, verify: false).parsed_response

    # response.make_response_pretty(type)!
    response
  end


  def make_response_pretty!(response, type)
    # how does this work according to "response.make_response_pretty(type)!" 
    
  end

  def change_page(url) 
  end

end


