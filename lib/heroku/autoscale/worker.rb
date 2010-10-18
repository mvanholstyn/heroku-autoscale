require File.expand_path(File.join(File.dirname(__FILE__), "base"))

module Heroku
  module Autoscale
    class Worker < Base
      def autoscale(env)
        # dont do anything if we scaled too frequently ago
        # return if (Time.now - last_scaled) < options[:min_frequency]

        original_workers = workers = current_workers(env)
        depth = queue_depth(env)

        workers -= 1 if depth <= options[:queue_depth_low]
        workers += 1 if depth >= options[:queue_depth_high]

        workers = options[:min_workers] if workers < options[:min_workers]
        workers = options[:max_workers] if workers > options[:max_workers]
        workers = 1 if workers < 1
        workers = depth if workers > depth

        set_workers(workers) if workers != original_workers
      end

      def current_workers(env)
        heroku.info(options[:app_name])[:workers].to_i
      end

      def default_options
        {
          :defer            => true,
          :min_workers      => 0,
          :max_workers      => 24,
          :queue_depth_low  => 0,
          :queue_depth_high => 1,
          :min_frequency    => 10  # seconds
        }
      end

      def queue_depth(env)
        env['HTTP_X_HEROKU_QUEUE_DEPTH'].to_i
      end

      def set_workers(count)
        heroku.set_workers(options[:app_name], count)
        @last_scaled = Time.now
      end
    end
  end
end
