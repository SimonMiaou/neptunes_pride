# frozen_string_literal: true

require 'test_helper'

describe NeptunesPride::Client do
  describe '#authenticate!' do
    before do
      @username = Faker::Internet.email
      @password = SecureRandom.hex
      @returned_cookie = "auth=#{SecureRandom.hex}; Max-Age=604800; Path=/; expires=Mon, 06-Jul-2020 17:16:42 GMT"

      @client = NeptunesPride::Client.new(username: @username, password: @password)
    end

    describe 'when authentication is successful' do
      it 'store the received cookie' do
        stub_login_request('["meta:login_success",  ""]')

        @client.authenticate!

        _(@client.cookie).must_equal(@returned_cookie)
      end
    end

    describe 'when there is an error' do
      before do
        @api_error = ['account_not_found', 'login_wrong_password'].sample
      end

      it 'store the received cookie' do
        stub_login_request('["meta:error",  "' + @api_error + '"]')

        error = _(-> { @client.authenticate! }).must_raise(NeptunesPride::ApiError)

        _(error.message).must_equal(@api_error)
        _(@client.cookie).must_be_nil
      end
    end

    def stub_login_request(returned_body) # rubocop:disable Metrics/MethodLength
      stub_request(:post, 'https://np.ironhelmet.com/arequest/login')
        .with(body: { 'alias' => @username,
                      'password' => @password,
                      'type' => 'login' },
              headers: { 'Accept' => '*/*',
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'User-Agent' => 'Ruby' })
        .to_return(status: 200,
                   body: returned_body,
                   headers: { 'Content-Type' => 'application/json',
                              'Set-Cookie' => @returned_cookie })
    end
  end
end
