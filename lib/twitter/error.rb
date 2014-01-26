require 'twitter/rate_limit'

module Twitter
  # Custom error class for rescuing from all Twitter errors
  class Error < StandardError
    attr_reader :cause, :code, :rate_limit
    alias_method :wrapped_exception, :cause

    # If error code is missing see https://dev.twitter.com/docs/error-codes-responses
    module Codes
      AUTHENTICATION_PROBLEM       = 32
      RESOURCE_NOT_FOUND           = 34
      SUSPENDED_ACCOUNT            = 64
      DEPRECATED_CALL              = 68
      RATE_LIMIT_EXCEEDED          = 88
      INVALID_OR_EXPIRED_TOKEN     = 89
      UNABLE_TO_VERIFY_CREDENTIALS = 99
      OVER_CAPACITY                = 130
      INTERNAL_ERROR               = 131
      OAUTH_TIMESTAMP_OUT_OF_RANGE = 135
      FOLLOW_ALREADY_REQUESTED     = 160
      FOLLOW_LIMIT_EXCEEDED        = 161
      PROTECTED_STATUS             = 179
      OVER_UPDATE_LIMIT            = 185
      DUPLICATE_STATUS             = 187
      BAD_AUTHENTICATION_DATA      = 215
      LOGIN_VERIFICATION_NEEDED    = 231
      ENDPOINT_RETIRED             = 251
    end

    class << self
      # Create a new error from an HTTP response
      #
      # @param response [HTTP::Response]
      # @return [Twitter::Error]
      def from_response(response)
        message, code = parse_error(response.parse)
        new(message, response.headers, code)
      end

    private

      def parse_error(body)
        if body.nil?
          ['', nil]
        elsif body[:error]
          [body[:error], nil]
        elsif body[:errors]
          extract_message_from_errors(body)
        end
      end

      def extract_message_from_errors(body)
        first = Array(body[:errors]).first
        if first.is_a?(Hash)
          [first[:message].chomp, first[:code]]
        else
          [first.chomp, nil]
        end
      end
    end

    # Initializes a new Error object
    #
    # @param exception [Exception, String]
    # @param response_headers [Hash]
    # @param code [Integer]
    # @return [Twitter::Error]
    def initialize(message = '', response_headers = {}, code = nil)
      @message = message
      @rate_limit = Twitter::RateLimit.new(response_headers)
      @code = code
    end

    class ConfigurationError < ::ArgumentError; end

    # Raised when Twitter returns a 4xx HTTP status code
    class ClientError < self; end

    # Raised when Twitter returns the HTTP status code 400
    class BadRequest < ClientError; end

    # Raised when Twitter returns the HTTP status code 401
    class Unauthorized < ClientError; end

    # Raised when Twitter returns the HTTP status code 403
    class Forbidden < ClientError; end

    # Raised when a Tweet has already been favorited
    class AlreadyFavorited < Forbidden; end

    # Raised when a Tweet has already been posted
    class AlreadyPosted < Forbidden; end

    # Raised when a Tweet has already been retweeted
    class AlreadyRetweeted < Forbidden; end

    # Raised when Twitter returns the HTTP status code 404
    class NotFound < ClientError; end

    # Raised when Twitter returns the HTTP status code 406
    class NotAcceptable < ClientError; end

    # Raised when Twitter returns the HTTP status code 422
    class UnprocessableEntity < ClientError; end

    # Raised when Twitter returns the HTTP status code 429
    class TooManyRequests < ClientError; end
    EnhanceYourCalm = TooManyRequests # rubocop:disable ConstantName
    RateLimited = TooManyRequests # rubocop:disable ConstantName

    # Raised when Twitter returns a 5xx HTTP status code
    class ServerError < self; end

    # Raised when Twitter returns the HTTP status code 500
    class InternalServerError < ServerError; end

    # Raised when Twitter returns the HTTP status code 502
    class BadGateway < ServerError; end

    # Raised when Twitter returns the HTTP status code 503
    class ServiceUnavailable < ServerError; end

    # Raised when Twitter returns the HTTP status code 504
    class GatewayTimeout < ServerError; end
  end
end
