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
        stub_login_request("[\"meta:error\",  \"#{@api_error}\"]")

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

  describe '#full_universe_report' do
    before do
      @cookie = "auth=#{SecureRandom.hex}; Max-Age=604800; Path=/; expires=Mon, 06-Jul-2020 17:16:42 GMT"
      @game_number = 6_554_844_626_944_000
      @returned_cookie = "auth=#{SecureRandom.hex}; Max-Age=604800; Path=/; expires=Mon, 06-Jul-2020 17:16:42 GMT"

      @client = NeptunesPride::Client.new(cookie: @cookie)
    end

    it 'return raw payload' do
      stub_request(:post, 'https://np.ironhelmet.com/trequest/order')
        .with(body: { 'game_number' => @game_number,
                      'order' => 'full_universe_report',
                      'type' => 'order' },
              headers: { 'Accept' => '*/*',
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'Cookie' => @cookie,
                         'User-Agent' => 'Ruby' })
        .to_return(status: 200,
                   body: File.read('test/fixtures/full_universe_report.json'),
                   headers: { 'Content-Type' => 'application/json',
                              'Set-Cookie' => @returned_cookie })

      response = @client.full_universe_report(@game_number)

      _(response.class).must_equal(Hash)
      _(response.keys).must_equal(['event', 'report'])
    end

    it 'save the new cookie' do
      stub_request(:post, 'https://np.ironhelmet.com/trequest/order')
        .with(body: { 'game_number' => @game_number,
                      'order' => 'full_universe_report',
                      'type' => 'order' },
              headers: { 'Accept' => '*/*',
                         'Content-Type' => 'application/x-www-form-urlencoded',
                         'Cookie' => @cookie,
                         'User-Agent' => 'Ruby' })
        .to_return(status: 200,
                   body: File.read('test/fixtures/full_universe_report.json'),
                   headers: { 'Content-Type' => 'application/json',
                              'Set-Cookie' => @returned_cookie })

      @client.full_universe_report(@game_number)

      _(@client.cookie).must_equal(@returned_cookie)
    end

    describe 'when there is an error (and JSON is invalid)' do
      it 'raise an exception' do
        stub_request(:post, 'https://np.ironhelmet.com/trequest/order')
          .with(body: { 'game_number' => @game_number,
                        'order' => 'full_universe_report',
                        'type' => 'order' },
                headers: { 'Accept' => '*/*',
                           'Content-Type' => 'application/x-www-form-urlencoded',
                           'Cookie' => @cookie,
                           'User-Agent' => 'Ruby' })
          .to_return(status: 200,
                     body: '{"event": "None", "report": None}',
                     headers: { 'Content-Type' => 'application/json',
                                'Set-Cookie' => @returned_cookie })

        _(-> { @client.full_universe_report(@game_number) }).must_raise(JSON::ParserError)
      end
    end
  end
end
