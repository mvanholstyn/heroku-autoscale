# Heroku::Autoscale

## Installation

    # Gemfile
    gem 'heroku-autoscale'

## Usage (Rails 2.x)

    # config/environment.rb
    config.middleware.use Heroku::Autoscale,
      :username  => ENV["HEROKU_USERNAME"],
      :password  => ENV["HEROKU_PASSWORD"],
      :app_name  => ENV["HEROKU_APP_NAME"],
      :min_dynos => 2,
      :max_dynos => 5,
      :queue_wait_low  => 100,  # milliseconds
      :queue_wait_high => 5000, # milliseconds
      :min_frequency   => 10    # seconds
    
## Usage (Rails 3 / Rack)

    # config.ru
    use Heroku::Autoscale,
      :username  => ENV["HEROKU_USERNAME"],
      :password  => ENV["HEROKU_PASSWORD"],
      :app_name  => ENV["HEROKU_APP_NAME"],
      :min_dynos => 2,
      :max_dynos => 5,
      :queue_wait_low  => 100,  # milliseconds
      :queue_wait_high => 5000, # milliseconds
      :min_frequency   => 10    # seconds


begin
  require 'heroku/autoscale/dyno/rack'

  config.middleware.use Heroku::Autoscale::Dyno::Rack,
    :username        => ENV["HEROKU_USERNAME"],
    :password        => ENV["HEROKU_PASSWORD"],
    :app_name        => ENV["HEROKU_APP_NAME"],
    :min_dynos       => 1,
    :max_dynos       => 10,
    :queue_wait_low  => 100, # milliseconds
    :queue_wait_high => 1000 # milliseconds
rescue LoadError => e
  puts "*********** COULDNT LOAD DYNO AUTOSCALING ***********"
end

config.after_initialize do
  begin
    require 'delayed_job'

    Delayed::Worker.guess_backend

    require 'heroku/autoscale/worker/delayed_job'

    Heroku::Autoscale::Worker::DelayedJob.configure(
      :username         => ENV["HEROKU_USERNAME"],
      :password         => ENV["HEROKU_PASSWORD"],
      :app_name         => ENV["HEROKU_APP_NAME"],
      :min_workers      => 0,
      :max_workers      => 10,
      :queue_depth_low  => 0,
      :queue_depth_high => 1
    )
  rescue LoadError => e
    puts "*********** COULDNT LOAD WORKER AUTOSCALING ***********"
  end
end