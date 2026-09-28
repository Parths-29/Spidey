# Changelog

## [1.0.0] - 2024-09-28

### Added
- Initial release of Spidey gem
- Elegant `crawl` / `process` DSL
- `Spidey::Response` with Nokogiri integration (`css`, `xpath`, `links`, `title`, `resolve`)
- `Spidey::Runner` — zero-dependency HTTP runner using `net/http`
- `Spidey::Configuration` with rate limiting, retries, timeouts, custom headers
- ActiveJob integration (automatic background jobs in Rails)
- Rake tasks: `spidey:run`, `spidey:list`, `spidey:debug`
- Rails Railtie with logger auto-configuration
- Inheritance support — subclass crawlers inherit parent config
- Interactive web dashboard with live crawl simulator
