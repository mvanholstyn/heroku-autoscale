require File.expand_path(File.join(File.dirname(__FILE__), "base"))

module Heroku
  module Autoscale
    class Dyno < Base
      def autoscale(env)
        # dont do anything if we scaled too frequently ago
        # return if (Time.now - last_scaled) < options[:min_frequency]

        original_dynos = dynos = current_dynos(env)
        wait = queue_wait(env)

        dynos -= 1 if wait <= options[:queue_wait_low]
        dynos += 1 if wait >= options[:queue_wait_high]

        dynos = options[:min_dynos] if dynos < options[:min_dynos]
        dynos = options[:max_dynos] if dynos > options[:max_dynos]
        dynos = 1 if dynos < 1

        set_dynos(dynos) if dynos != original_dynos
      end

      def current_dynos
        (env["HTTP_X_HEROKU_DYNOS_IN_USE"] || heroku.info(options[:app_name])[:dynos]).to_i
      end

      def default_options
        {
          :defer           => true,
          :min_dynos       => 1,
          :max_dynos       => 24,
          :queue_wait_low  => 0,  # milliseconds
          :queue_wait_high => 1,  # milliseconds
          :min_frequency   => 10  # seconds
        }
      end

      def queue_wait(env)
        env["HTTP_X_HEROKU_QUEUE_WAIT_TIME"].to_i
      end

      def queue_depth(env)
        env['HTTP_X_HEROKU_QUEUE_DEPTH'].to_i
      end

      def set_dynos(count)
        heroku.set_dynos(options[:app_name], count)
        @last_scaled = Time.now
      end
    end
  end
end
