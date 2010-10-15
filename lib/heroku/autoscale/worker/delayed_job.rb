require File.expand_path(File.join(File.dirname(__FILE__), "..", "worker"))

module Heroku
  module Autoscale
    class Worker
      module DelayedJob
        def self.configure(options = {})
          Delayed::Job.send(:include, Heroku::Autoscale::Worker::DelayedJob)
          Delayed::Job.autoscaler_options = options
        end
        
        def self.included(base)
          base.send :extend, ClassMethods
          base.class_eval do
            after_create "self.class.autoscale"
            after_destroy "self.class.autoscale"
            after_update "self.class.autoscale", :unless => Proc.new { |j| j.failed_at.nil? }
          end
        end
        
        module ClassMethods
          attr_accessor :autoscaler_options

          def autoscaler
            @autoscaler ||= Heroku::Autoscale::Worker.new(autoscaler_options)
          end

          def autoscaler_env
            { 'HTTP_X_HEROKU_QUEUE_DEPTH' => self.count(:conditions => { :failed_at => nil }) }
          end

          def autoscale
            autoscaler.autoscale_or_defer(autoscaler_env)
          end
        end
      end
    end
  end
end

