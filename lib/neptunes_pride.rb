# frozen_string_literal: true

require 'neptunes_pride/client'
require 'neptunes_pride/version'

module NeptunesPride
  class Error < StandardError; end

  class ApiError < Error; end

  class NotAuthenticated < Error; end
end
