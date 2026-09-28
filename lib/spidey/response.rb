# frozen_string_literal: true

require "nokogiri"

module Spidey
  # Wraps an HTTP response and provides convenient HTML/XML parsing
  class Response
    attr_reader :uri, :status, :headers, :body, :crawled_at

    def initialize(uri:, status:, headers:, body:)
      @uri        = uri
      @status     = status
      @headers    = headers
      @body       = body
      @crawled_at = Time.now
    end

    # @return [Nokogiri::HTML::Document]
    def document
      @document ||= Nokogiri::HTML(body)
    end

    # Delegate CSS / XPath queries directly
    def css(*args, &block)       = document.css(*args, &block)
    def xpath(*args, &block)     = document.xpath(*args, &block)
    def at_css(*args, &block)    = document.at_css(*args, &block)
    def at_xpath(*args, &block)  = document.at_xpath(*args, &block)
    def text                     = document.text
    def title                    = at_css("title")&.text&.strip

    # @return [Boolean]
    def success?  = status.between?(200, 299)
    def redirect? = status.between?(300, 399)
    def error?    = status >= 400

    # Resolve a relative or absolute href against the current page URI
    # @param href [String]
    # @return [String]
    def resolve(href)
      URI.join(uri, href).to_s
    rescue URI::Error
      href
    end

    # Extract all links from the page
    # @param selector [String] CSS selector for anchor elements
    # @return [Array<String>]
    def links(selector = "a[href]")
      css(selector).filter_map do |a|
        href = a["href"]&.strip
        next if href.nil? || href.empty? || href.start_with?("#", "mailto:", "javascript:")
        resolve(href)
      end.uniq
    end

    def to_s
      "#<Spidey::Response [#{status}] #{uri}>"
    end

    def inspect = to_s
  end
end
