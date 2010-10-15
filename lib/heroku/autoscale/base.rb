require "eventmachine"
require "heroku"

module Heroku
  module Autoscale
    VERSION = "0.2.2"

    class Base
      attr_reader :options, :last_scaled

      def initialize(options={})
        @options = default_options.merge(options)
        @last_scaled = Time.now - 60
        check_options!
      end

      def check_options!
        errors = []
        errors << "Must supply :username to Heroku::Autoscale" unless options[:username]
        errors << "Must supply :password to Heroku::Autoscale" unless options[:password]
        errors << "Must supply :app_name to Heroku::Autoscale" unless options[:app_name]
        raise errors.join(" / ") unless errors.empty?
      end

      def heroku
        @heroku ||= Heroku::Client.new(options[:username], options[:password])
      end
      
      def autoscale_or_defer(env)
        if options[:defer]
          EventMachine.defer { autoscale(env) }
        else
          autoscale(env)
        end
      end
    end
  end
end
