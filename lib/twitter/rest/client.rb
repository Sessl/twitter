require 'base64'
require 'http'
require 'json'
require 'timeout'
require 'twitter/client'
require 'twitter/error'
require 'twitter/rest/api/direct_messages'
require 'twitter/rest/api/favorites'
require 'twitter/rest/api/friends_and_followers'
require 'twitter/rest/api/help'
require 'twitter/rest/api/lists'
require 'twitter/rest/api/oauth'
require 'twitter/rest/api/places_and_geo'
require 'twitter/rest/api/saved_searches'
require 'twitter/rest/api/search'
require 'twitter/rest/api/spam_reporting'
require 'twitter/rest/api/suggested_users'
require 'twitter/rest/api/timelines'
require 'twitter/rest/api/trends'
require 'twitter/rest/api/tweets'
require 'twitter/rest/api/undocumented'
require 'twitter/rest/api/users'

module Twitter
  module REST
    # Wrapper for the Twitter REST API
    #
    # @note All methods have been separated into modules and follow the same grouping used in {http://dev.twitter.com/doc the Twitter API Documentation}.
    # @see http://dev.twitter.com/pages/every_developer
    class Client < Twitter::Client
      include Twitter::REST::API::DirectMessages
      include Twitter::REST::API::Favorites
      include Twitter::REST::API::FriendsAndFollowers
      include Twitter::REST::API::Help
      include Twitter::REST::API::Lists
      include Twitter::REST::API::OAuth
      include Twitter::REST::API::PlacesAndGeo
      include Twitter::REST::API::SavedSearches
      include Twitter::REST::API::Search
      include Twitter::REST::API::SpamReporting
      include Twitter::REST::API::SuggestedUsers
      include Twitter::REST::API::Timelines
      include Twitter::REST::API::Trends
      include Twitter::REST::API::Tweets
      include Twitter::REST::API::Undocumented
      include Twitter::REST::API::Users
      attr_accessor :bearer_token
      attr_writer :connection_options, :middleware
      ENDPOINT = 'https://api.twitter.com'

      # Perform an HTTP GET request
      def get(path, params = {})
        header = auth_header(:get, path, params, params)
        request(:get, path, {:params => params}, :authorization => header)
      end

      # Perform an HTTP POST request
      def post(path, params = {})
        signature_params = params.values.any? { |value| value.respond_to?(:to_io) } ? {} : params
        header = auth_header(:post, path, params, signature_params)
        request(:post, path, {:form => params}, :authorization => header)
      end

      # @return [Boolean]
      def bearer_token?
        !!bearer_token
      end

      # @return [Boolean]
      def credentials?
        super || bearer_token?
      end

    private

      def request(method, path, params = {}, headers = {}) # rubocop:disable CyclomaticComplexity, MethodLength
        response = HTTP.with(headers).send(method, ENDPOINT + path, params)
        handle_exceptions(response)
        response.parse
      rescue JSON::ParserError
        response.to_s.empty? ? nil : response.to_s
      end

      def handle_exceptions(response)
        case response.code
        when 400
          fail(Twitter::Error::BadRequest.from_response(response))
        when 401
          fail(Twitter::Error::Unauthorized.from_response(response))
        when 403
          error = Twitter::Error::Forbidden.from_response(response)
          case error.message
          when 'You have already favorited this status.'
            fail(Twitter::Error::AlreadyFavorited.from_response(response))
          when 'Status is a duplicate.'
            fail(Twitter::Error::AlreadyPosted.from_response(response))
          when 'sharing is not permissible for this status (Share validations failed)'
            fail(Twitter::Error::AlreadyRetweeted.from_response(response))
          else
            fail(error)
          end
        when 404
          fail(Twitter::Error::NotFound.from_response(response))
        when 406
          fail(Twitter::Error::NotAcceptable.from_response(response))
        when 422
          fail(Twitter::Error::UnprocessableEntity.from_response(response))
        when 429
          fail(Twitter::Error::TooManyRequests.from_response(response))
        when 500
          fail(Twitter::Error::InternalServerError.from_response(response))
        when 501
          fail(Twitter::Error::BadGateway.from_response(response))
        when 502
          fail(Twitter::Error::ServiceUnavailable.from_response(response))
        when 503
          fail(Twitter::Error::GatewayTimeout.from_response(response))
        end
      end

      def auth_header(method, path, params = {}, signature_params = params)
        if !user_token?
          @bearer_token = token unless bearer_token?
          bearer_auth_header
        else
          oauth_auth_header(method, ENDPOINT + path, signature_params).to_s
        end
      end

      def bearer_auth_header
        token = bearer_token.is_a?(Twitter::Token) && bearer_token.bearer? ? bearer_token.access_token : bearer_token
        "Bearer #{token}"
      end

      # Base64.strict_encode64 is not available on Ruby 1.8.7
      def strict_encode64(str)
        Base64.encode64(str).gsub("\n", '')
      end
    end
  end
end
