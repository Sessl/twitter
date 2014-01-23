require 'helper'

describe Twitter::Error do

  before do
    @client = Twitter::REST::Client.new(:consumer_key => 'CK', :consumer_secret => 'CS', :access_token => 'AT', :access_token_secret => 'AS')
  end

  describe '#message' do
    it 'returns the message of the cause' do
      error = Twitter::Error.new(Timeout::Error.new('execution expired'))
      expect(error.message).to eq('execution expired')
    end
  end

  describe '#rate_limit' do
    it 'returns the cause' do
      error = Twitter::Error.new(Timeout::Error.new('execution expired'))
      expect(error.rate_limit).to be_a Twitter::RateLimit
    end
  end

  describe '#cause' do
    it 'returns the cause' do
      error = Twitter::Error.new(Timeout::Error.new('execution expired'))
      expect(error.cause).to be_a Timeout::Error
    end
  end
end
