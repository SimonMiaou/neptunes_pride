# frozen_string_literal: true

require 'net/http'
require 'uri'

module NeptunesPride
  # Class responsible for API calls
  class Client
    attr_reader :cookie

    def initialize(username: nil, password: nil, cookie: nil)
      @cookie = cookie
      @password = password
      @username = username
    end

    def authenticate! # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      url = URI('https://np.ironhelmet.com/arequest/login')

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form(alias: username,
                                         password: password,
                                         type: 'login')

      response = https.request(request)
      body = JSON.parse(response.read_body)

      raise NeptunesPride::ApiError, body[1] if body[0] == 'meta:error'

      @cookie = response['Set-Cookie']
    end

    def full_universe_report(game_number) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      raise NeptunesPride::NotAuthenticated unless authenticated?

      url = URI('https://np.ironhelmet.com/trequest/order')

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request['Cookie'] = cookie
      request.body = URI.encode_www_form(game_number: game_number.to_s,
                                         order: 'full_universe_report',
                                         type: 'order')

      response = https.request(request)
      @cookie = response['Set-Cookie']
      JSON.parse(response.read_body)
    end

    private

    attr_reader :username, :password

    def authenticated?
      !cookie.nil?
    end
  end
end
