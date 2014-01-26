require 'base64'
require 'http'
require 'json'
require 'timeout'
require 'twitter/client'
require 'twitter/error'
require 'twitter/error/bad_gateway'
require 'twitter/error/bad_request'
require 'twitter/error/configuration_error'
require 'twitter/error/forbidden'
require 'twitter/error/gateway_timeout'
require 'twitter/error/internal_server_error'
require 'twitter/error/not_acceptable'
require 'twitter/error/not_found'
require 'twitter/error/service_unavailable'
require 'twitter/error/too_many_requests'
require 'twitter/error/unauthorized'
require 'twitter/error/unprocessable_entity'
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

      def request(method, path, params = {}, headers = {})
        response = HTTP.with(headers).send(method, ENDPOINT + path, params)
        if response.code != 200
          error_class = Twitter::Error.errors[response.code]
          error = error_class.new(response)
          fail(error)
        end
        response.parse
      rescue JSON::ParserError
        response.to_s.empty? ? nil : response.to_s
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
