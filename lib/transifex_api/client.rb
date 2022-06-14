module TransifexApi
  class Client
    class ApiFailure < StandardError; end
    class BadRequest < StandardError; end
    class NotFound < StandardError; end
    class NotAllowed < StandardError; end
    class NotAuthorised < StandardError; end

    BASE_URL = 'https://rest.api.transifex.com/'.freeze
    ORGANIZATION = 'energy-sparks'.freeze

    def initialize(api_key, project, connection = nil)
      @api_key = api_key
      @project = project
      @connection = connection
    end

    def get_languages
      url = make_url("projects/#{project_id}/languages")
      get_data(url)
    end

    def list_resources
      url = add_filter("resources")
      get_data(url)
    end

    def create_resource(name, slug)
      url = make_url("resources")
      post_data(url, resource_data(name, slug, project_id))
    end

    private

    def headers
      {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/vnd.api+json'
      }
    end

    def add_filter(path)
      path + "?filter[project]=#{project_id}"
    end

    def make_url(path)
      path
    end

    def project_id
      "o:#{ORGANIZATION}:p:#{@project}"
    end

    def connection
      @connection ||= Faraday.new(BASE_URL, headers: headers)
    end

    def get_data(url)
      response = connection.get(url)
      process_response(response)
    end

    def post_data(url, data)
      response = connection.post(url, data.to_json)
      process_response(response)
    end

    def process_response(response)
      raise BadRequest.new(error_message(response)) if response.status == 400
      raise NotAuthorised.new(error_message(response)) if response.status == 401
      raise NotAllowed.new(error_message(response)) if response.status == 403
      raise NotFound.new(error_message(response)) if response.status == 404
      raise ApiFailure.new(error_message(response)) unless response.success?
      JSON.parse(response.body)['data']
    end

    def error_message(response)
      data = JSON.parse(response.body)
      if data['errors']
        error = data['errors'][0]
        error['title']
      else
        response.body
      end
    rescue
      #problem parsing or traversing json, return original api error
      response.body
    end

    def resource_data(name, slug, project_id)
      {
        "data": {
          "attributes": {
            "accept_translations": true,
            "name": name,
            "slug": slug,
          },
          "relationships": {
            "i18n_format": {
              "data": {
                "id": "YML_KEY",
                "type": "i18n_formats"
              }
            },
            "project": {
              "data": {
                "id": project_id,
                "type": "projects"
              }
            }
          },
          "type": "resources"
        }
      }
    end
  end
end
