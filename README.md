# ApplicasterLogger

Dispatches all Rails and DelayedJob log events to logstash

Combines [Lograge](https://github.com/roidrage/lograge) with [logstash-logger](https://github.com/dwbutler/logstash-logger)

## Installation

Add this line to your application's Gemfile:

    gem 'applicaster-logger'

And then execute:

    $ bundle

## Usage

1. Enable it for the relevant environments, e.g. production:

  ```ruby
  # config/environments/production.rb
  MyApp::Application.configure do
    config.applicaster_logger.enabled = true
  end
  ```

  defaults to: `ENV["LOGSTASH_URI"].present?`

2. Configuring logstash output:

  ```ruby
  # config/environments/production.rb
  MyApp::Application.configure do
    config.applicaster_logger.logstash_config = { type: :redis }
  end
  ```
  
  defaults to: `{ uri: ENV["LOGSTASH_URI"] }` if `LOGSTASH_URI` is set or `{ type: :stdout }` otherwise

  For available options see: https://github.com/dwbutler/logstash-logger#basic-usage

3. To set the application name:

  ```ruby
  # config/environments/production.rb
  MyApp::Application.configure do
    config.applicaster_logger.application_name = "my_best_app"
  end
  ```
  defaults to: `Rails.application.class.parent.to_s.underscore`

4. To separately control the Sidekiq logging level:

  ```ruby
  # config/environments/production.rb
  MyApp::Application.configure do
    config.applicaster_logger.sidekiq_log_level = Logger::ERROR # Logger::DEBUG etc..
  end
  ```
  defaults to `applicaster_logger.level`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
