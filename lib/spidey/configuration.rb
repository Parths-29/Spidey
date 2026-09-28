# frozen_string_literal: true

module Spidey
  # Global configuration for the Spidey gem
  class Configuration
    attr_accessor :logger, :max_concurrency, :request_timeout,
                  :follow_redirects, :default_headers, :rate_limit,
                  :max_retries, :retry_delay, :respect_robots_txt

    def initialize
      @logger           = Logger.new($stdout, level: :info)
      @max_concurrency  = 5
      @request_timeout  = 30
      @follow_redirects = true
      @default_headers  = { "User-Agent" => "Spidey/#{Spidey::VERSION} Ruby Web Crawler" }
      @rate_limit       = nil   # requests per second (nil = unlimited)
      @max_retries      = 3
      @retry_delay      = 1.0  # seconds
      @respect_robots_txt = false
    end
  end
end
