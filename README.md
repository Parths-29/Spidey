<div align="center">
  <h1>🕷 Spidey</h1>
  <h3>Your Friendly Neighbourhood Web Crawler</h3>
  <p>
    <a href="https://github.com/Parths-29/Spidey/actions"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Parths-29/Spidey/ci.yml?style=flat-square&label=tests"/></a>
    <img alt="Ruby version" src="https://img.shields.io/badge/ruby-%3E%3D%203.0-red?style=flat-square"/>
    <img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"/>
    <img alt="Gem version" src="https://img.shields.io/badge/gem-v1.0.0-orange?style=flat-square"/>
  </p>
</div>

---

Spidey is a modern, dependency-light Ruby gem for crawling and processing web pages. No bloat, just a clean DSL that turns any class into a fully-featured web crawler.

## Features

- ⚡ **Elegant DSL** — `crawl` & `process` blocks read like prose
- 🔄 **Auto Retry** — configurable retries with exponential backoff
- 🚀 **ActiveJob Ready** — each request becomes a background job automatically
- 🎯 **Nokogiri Powered** — `css()`, `xpath()`, `links()` on every response
- ⚙️ **Rate Limiting** — be a good citizen, configure requests/second
- 🧬 **Inheritance** — share config across crawler families

## Installation

```ruby
# Gemfile
gem "spidey"
```

```bash
bundle install
# or: gem install spidey
```

## Quick Start

```ruby
require "spidey"

class HackerNewsCrawler
  include Spidey

  crawl "https://news.ycombinator.com/" do |response|
    response.css("a.titlelink").each do |a|
      process! a["href"], :story
    end
  end

  process :story do |response|
    puts "#{response.uri} — #{response.title}"
  end
end

HackerNewsCrawler.crawl!
```

## Configuration

```ruby
Spidey.configure do |config|
  config.logger           = Logger.new("log/spidey.log", level: :debug)
  config.rate_limit       = 2          # requests/second
  config.request_timeout  = 15         # seconds
  config.max_retries      = 3
  config.retry_delay      = 1.0        # exponential backoff base
  config.default_headers  = { "User-Agent" => "MyBot/1.0" }
  config.follow_redirects = true
end
```

## Rails + ActiveJob

```ruby
class ProductCrawler < ApplicationJob
  queue_as :crawlers
  include Spidey

  crawl "https://shop.example.com/products" do |response|
    response.css("a.product-link").each { |a| process! response.resolve(a["href"]), :product }
  end

  process :product do |response|
    Product.create!(url: response.uri.to_s, title: response.css("h1").text)
  end
end

ProductCrawler.crawl!
```

## Response API

| Method | Description |
|--------|-------------|
| `.css(selector)` | Nokogiri CSS query |
| `.xpath(expr)` | XPath query |
| `.links(selector?)` | Extract all absolute URLs |
| `.title` | Page `<title>` text |
| `.resolve(href)` | Resolve relative → absolute URL |
| `.success?` | `status` 2xx |
| `.error?` | `status` 4xx/5xx |

## Rake Tasks (Rails)

```bash
rake spidey:run             # Run all crawlers
rake spidey:run[MyCrawler]  # Run specific crawler
rake spidey:list            # List registered crawlers
rake spidey:debug[name,url] # Debug a single URL
```

## Dashboard

Open `dashboard/index.html` in your browser for the interactive web dashboard with a live crawl simulator.

## Development

```bash
git clone https://github.com/Parths-29/Spidey
cd Spidey
bundle install
bundle exec rspec
```

## License

MIT — see [LICENSE.txt](LICENSE.txt).
