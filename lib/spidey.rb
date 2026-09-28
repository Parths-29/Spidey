# frozen_string_literal: true

require "logger"
require "uri"
require "net/http"
require "nokogiri"

require_relative "spidey/version"
require_relative "spidey/configuration"
require_relative "spidey/response"
require_relative "spidey/runner"
require_relative "spidey/railtie" if defined?(Rails)

# Spidey – Your friendly neighbourhood web crawler 🕷
#
# Usage:
#   class MySpider
#     include Spidey
#
#     crawl "https://example.com" do |response|
#       response.links.each { |url| process! url, :page }
#     end
#
#     process :page do |response|
#       puts "#{response.uri} — #{response.title}"
#     end
#   end
#
#   MySpider.crawl!
module Spidey
  # ---------- Module-level config & helpers ----------------------------------

  class << self
    # @return [Spidey::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the configuration object for block-style setup.
    def configure
      yield configuration
    end

    # @return [Logger]
    def logger
      configuration.logger
    end

    # Internal registry of all crawler classes
    # @return [Array<Class>]
    def list
      @list ||= []
    end

    def add(klass)
      list << klass unless list.include?(klass)
    end

    # Run all (or a named) crawler
    def run(name = nil)
      targets = name ? [find(name)] : list
      targets.compact.each(&:crawl!)
    end

    # Find a crawler class by its underscored name
    def find(name)
      list.detect { |c| c.name.split("::").last.gsub(/([A-Z])/, '_\1').downcase.delete_prefix("_") == name.to_s }
    end
  end

  # ---------- Concern --------------------------------------------------------

  def self.included(base)
    Spidey.add(base)

    base.instance_variable_set(:@crawler, Runner.new)
    base.extend(ClassMethods)

    base.define_method(:logger) { self.class.crawler.headers }
  end

  module ClassMethods
    attr_reader :crawler

    # Register one or more starting URLs
    # @param urls [String, Array<String>]
    def crawl(*urls, &block)
      urls.flatten.each { |u| @crawler.start_at(u) }
      @crawler.register(:crawl, &block) if block
    end

    # Register a named processor
    # @param type [Symbol]
    def process(type, &block)
      @crawler.register(type, &block)
    end

    # Kick off crawling (class-level convenience)
    def crawl!
      new.crawl!
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@crawler, @crawler.dup)
      Spidey.add(subclass)
    end

    def name
      super || "AnonymousCrawler"
    end
  end

  # ---------- Instance methods -----------------------------------------------

  # Start crawling all registered URLs
  def crawl!
    self.class.crawler.stats[:start_time] = Time.now
    self.class.crawler.urls.each { |url| process!(url) }
    self.class.crawler.stats[:end_time] = Time.now
  end

  # @param url    [String]       URL to request
  # @param type   [Symbol, nil]  processor name; defaults to :crawl
  def process!(url, type = nil)
    perform(url, type)
  end

  # @param url  [String]
  # @param type [Symbol, nil]
  def perform(url, type = nil)
    handler = self.class.crawler.handler_for(type || :crawl)
    raise ArgumentError, "No handler registered for #{type.inspect}" unless handler

    response = self.class.crawler.request(url)
    instance_exec(response, &handler)
  rescue => e
    Spidey.logger.error("Error processing #{url}: #{e.message}")
    raise
  end

  # Human-readable name for this instance
  def name
    self.class.name.split("::").last
  end
end
