require File.expand_path(File.join(File.dirname(__FILE__), "..", "dyno"))

module Heroku
  module Autoscale
    class Dyno
      class Rack
        attr_reader :app

        def initialize(app, options = {})
          @app = app
          @autoscaler = Heroku::Autoscale::Dyno.new(options)
        end

        def call(env)
          @autoscaler.autoscale_or_defer(env)
          app.call(env)
        end
      end
    end
  end
end
