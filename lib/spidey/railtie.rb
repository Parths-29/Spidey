# frozen_string_literal: true

module Spidey
  # Rails integration — exposes `rake spidey:run` and `rake spidey:list`
  class Railtie < Rails::Railtie
    railtie_name :spidey

    rake_tasks do
      load File.expand_path("tasks.rake", __dir__)
    end

    initializer "spidey.logger" do
      Spidey.configuration.logger = Rails.logger if defined?(Rails.logger)
    end
  end
end
