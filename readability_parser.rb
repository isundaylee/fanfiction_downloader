class ReadabilityParser

  require 'json'
  require 'open-uri'
  require 'cgi'

  PARSE_URL = 'http://readability.com/api/content/v1/parser?url=%s&token=%s'

  def initialize(token)
    @token = token
  end

  def parse(url)
    url = PARSE_URL % [CGI.escape(url), @token]
    response = open(url).read

    JSON.parse(response)
  end

end