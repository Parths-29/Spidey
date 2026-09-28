# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spidey do
  let(:spider_class) do
    Class.new { include Spidey }
  end

  describe ".VERSION" do
    it "is defined and non-nil" do
      expect(Spidey::VERSION).not_to be_nil
    end
  end

  describe "configuration" do
    it "has a default User-Agent header" do
      expect(Spidey.configuration.default_headers["User-Agent"]).to include("Spidey")
    end

    it "supports block-style configure" do
      Spidey.configure { |c| c.max_retries = 5 }
      expect(Spidey.configuration.max_retries).to eq(5)
    end
  end

  describe ".crawl" do
    it "registers start URLs" do
      spider_class.crawl("https://example.com") {}
      expect(spider_class.crawler.urls).to include("https://example.com")
    end

    it "accepts multiple URLs" do
      spider_class.crawl("https://a.com", "https://b.com") {}
      expect(spider_class.crawler.urls).to eq(["https://a.com", "https://b.com"])
    end
  end

  describe ".process" do
    it "registers a named handler" do
      spider_class.process(:article) { |r| }
      expect(spider_class.crawler.handler_for(:article)).to be_a(Proc)
    end
  end

  describe "inheritance" do
    let(:base) do
      Class.new do
        include Spidey
        crawl("https://parent.com") {}
      end
    end

    let(:child) { Class.new(base) }

    it "inherits parent URLs" do
      expect(child.crawler.urls).to include("https://parent.com")
    end

    it "has an independent runner from parent" do
      expect(child.crawler).not_to be(base.crawler)
    end
  end

  describe "#crawl!" do
    let(:html) { "<html><head><title>Test</title></head><body><a href='/page'>link</a></body></html>" }

    before do
      stub_request(:get, "https://example.com")
        .to_return(status: 200, body: html, headers: { "Content-Type" => "text/html" })
    end

    it "makes an HTTP request and yields a Response" do
      received = nil
      spider_class.crawl("https://example.com") { |r| received = r }
      spider_class.crawl!
      expect(received).to be_a(Spidey::Response)
      expect(received.title).to eq("Test")
    end
  end

  describe Spidey::Response do
    let(:html) do
      "<html><body><a href='https://foo.com'>Foo</a><a href='/bar'>Bar</a></body></html>"
    end

    subject do
      Spidey::Response.new(
        uri:     URI("https://example.com"),
        status:  200,
        headers: {},
        body:    html
      )
    end

    it "parses CSS" do
      expect(subject.css("a").size).to eq(2)
    end

    it "extracts absolute links" do
      expect(subject.links).to include("https://foo.com", "https://example.com/bar")
    end

    it "reports success?" do
      expect(subject).to be_success
    end
  end
end
