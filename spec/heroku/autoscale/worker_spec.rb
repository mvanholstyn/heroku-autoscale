require "spec_helper"
require "heroku/autoscale/worker"

describe Heroku::Autoscale::Worker do

  include Rack::Test::Methods

  def noop
    lambda {}
  end

  describe "option validation" do
    it "requires username" do
      lambda { Heroku::Autoscale::Worker.new(noop) }.should raise_error(/Must supply :username/)
    end

    it "requires password" do
      lambda { Heroku::Autoscale::Worker.new(noop) }.should raise_error(/Must supply :password/)
    end

    it "requires app_name" do
      lambda { Heroku::Autoscale::Worker.new(noop) }.should raise_error(/Must supply :app_name/)
    end
  end

  describe "with valid options" do
    let(:app) do
      Heroku::Autoscale::Worker.new noop,
        :defer => false,
        :username => "test_username",
        :password => "test_password",
        :app_name => "test_app_name",
        :min_workers      => 1,
        :max_workers      => 10,
        :queue_depth_low  => 5,
        :queue_depth_high => 10,
        :min_frequency    => 10
    end

    it "scales up" do
      heroku = mock(Heroku::Client)
      heroku.info("test_app_name") { { :workers => 1 } }
      heroku.set_workers("test_app_name", 2)

      mock(app).heroku.times(any_times) { heroku }
      app.call({ "HTTP_X_HEROKU_QUEUE_DEPTH" => 11 })
    end

    it "scales down" do
      heroku = mock(Heroku::Client)
      heroku.info("test_app_name") { { :workers => 3 } }
      heroku.set_workers("test_app_name", 2)

      mock(app).heroku.times(any_times) { heroku }
      app.call({ "HTTP_X_HEROKU_QUEUE_DEPTH" => 4 })
    end

    it "wont go below one worker" do
      heroku = mock(Heroku::Client)
      heroku.info("test_app_name") { { :workers => 1 } }
      heroku.set_workers.times(0)

      mock(app).heroku.times(any_times) { heroku }
      app.call({ "HTTP_X_HEROKU_QUEUE_DEPTH" => 4 })
    end

    it "respects max workers" do
      heroku = mock(Heroku::Client)
      heroku.info("test_app_name") { { :workers => 10 } }
      heroku.set_workers.times(0)

      mock(app).heroku.times(any_times) { heroku }
      app.call({ "HTTP_X_HEROKU_QUEUE_DEPTH" => 11 })
    end

    it "respects min workers" do
      app.options[:min_workers] = 2
      heroku = mock(Heroku::Client)
      heroku.info("test_app_name") { { :workers => 2 } }
      heroku.set_workers.times(0)

      mock(app).heroku.times(any_times) { heroku }
      app.call({ "HTTP_X_HEROKU_QUEUE_DEPTH" => 4 })
    end

    it "doesnt flap" do
      heroku = mock(Heroku::Client)
      heroku.info("test_app_name").once { { :workers => 5 } }
      heroku.set_workers.with_any_args.once

      mock(app).heroku.times(any_times) { heroku }
      app.call({ "HTTP_X_HEROKU_QUEUE_DEPTH" => 4 })
      app.call({ "HTTP_X_HEROKU_QUEUE_DEPTH" => 4 })
    end
  end

end
