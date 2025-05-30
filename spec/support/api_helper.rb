# frozen_string_literal: true

module OpenFoodNetwork
  module ApiHelper
    def json_response
      json_response = JSON.parse(response.body)
      case json_response
      when Hash
        json_response.with_indifferent_access
      when Array
        json_response.map(&:with_indifferent_access)
      else
        json_response
      end
    end

    def json_response_ids
      json_response[:data]&.pluck(:id)
    end

    def json_error_detail
      json_response[:errors][0][:detail]
    end

    def assert_unauthorized!
      expect(json_response).to eq("error" => "You are not authorized to perform that action.")
      expect(response).to have_http_status :unauthorized
    end
  end
end
