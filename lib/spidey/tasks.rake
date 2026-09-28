# frozen_string_literal: true

namespace :spidey do
  # Ensure the Rails environment + eager-load all classes first
  task :environment => :environment do
    if defined?(Rails)
      ActiveSupport.run_load_hooks(:before_eager_load, Rails.configuration)
      Rails.configuration.eager_load_namespaces.each(&:eager_load!)
    end

    if defined?(Zeitwerk)
      Zeitwerk::Loader.eager_load_all
    end
  end

  desc "Run all crawlers (or pass name= to run a specific one)"
  task :run, [:crawler] => :environment do |_, args|
    Spidey.run(args[:crawler])
  end

  desc "List all registered crawlers"
  task list: :environment do
    crawlers = Spidey.list
    if crawlers.empty?
      puts "No crawlers registered."
    else
      puts "Registered crawlers:"
      crawlers.each { |c| puts "  - #{c.name}" }
    end
  end

  desc "Debug: run a specific crawler against a single URL"
  task :debug, [:crawler, :url, :type] => :environment do |_, args|
    crawler = Spidey.find(args[:crawler])
    raise "Crawler '#{args[:crawler]}' not found. Run `rake spidey:list` to see available crawlers." unless crawler

    crawler.new.perform(args[:url], args[:type]&.to_sym)
  end
end

# Shortcut: `rake spidey`
task spidey: "spidey:run"
