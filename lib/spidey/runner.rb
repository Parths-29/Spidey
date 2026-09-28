# frozen_string_literal: true

require "net/http"
require "uri"

module Spidey
  # Core crawl runner — handles URL registration, HTTP requests, retries and rate-limiting
  class Runner
    attr_reader :urls, :handlers, :headers, :stats

    def initialize
      @urls     = []
      @handlers = {}
      @headers  = Spidey.configuration.default_headers.dup
      @stats    = { requests: 0, errors: 0, start_time: nil, end_time: nil }
    end

    # ---------- Registration -------------------------------------------------

    def start_at(*urls)
      @urls.push(*urls.flatten)
    end

    def register(name, &handler)
      @handlers[name] = handler
    end

    def handler_for(name)
      @handlers[name]
    end

    # ---------- HTTP ---------------------------------------------------------

    # @param url [String]
    # @return [Spidey::Response]
    def request(url)
      uri      = URI.parse(url.to_s)
      attempts = 0

      begin
        attempts += 1
        resp = perform_request(uri)
        @stats[:requests] += 1

        Spidey.logger.debug("GET #{url} => #{resp.code}")
        rate_limit!

        Response.new(
          uri:     uri,
          status:  resp.code.to_i,
          headers: resp.each_header.to_h,
          body:    resp.body.to_s
        )
      rescue StandardError => e
        @stats[:errors] += 1
        if attempts < Spidey.configuration.max_retries
          Spidey.logger.warn("Retrying #{url} (attempt #{attempts}): #{e.message}")
          sleep(Spidey.configuration.retry_delay * attempts)
          retry
        else
          Spidey.logger.error("Failed #{url} after #{attempts} attempts: #{e.message}")
          raise
        end
      end
    end

    # ---------- Cloning -------------------------------------------------------

    def dup
      self.class.new.tap do |r|
        r.urls.replace(urls)
        r.handlers.update(handlers)
        r.headers.update(headers)
      end
    end

    protected

    attr_writer :headers

    private

    def perform_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl        = (uri.scheme == "https")
      http.open_timeout   = Spidey.configuration.request_timeout
      http.read_timeout   = Spidey.configuration.request_timeout

      req = Net::HTTP::Get.new(uri.request_uri)
      headers.each { |k, v| req[k] = v }

      response = http.request(req)

      # Follow redirects (up to 5 hops)
      if Spidey.configuration.follow_redirects && response.is_a?(Net::HTTPRedirection)
        location = response["location"]
        perform_request(URI.parse(location))
      else
        response
      end
    end

    def rate_limit!
      limit = Spidey.configuration.rate_limit
      return unless limit && limit > 0

      sleep(1.0 / limit)
    end
  end
end
