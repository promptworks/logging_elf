# LoggingElf
[![Build Status](https://travis-ci.org/promptworks/logging_elf.png?branch=master)](https://travis-ci.org/promptworks/logging_elf)
[![Gem Version](https://badge.fury.io/rb/logging_elf.png)](http://badge.fury.io/rb/logging_elf)
[![Code Climate](https://codeclimate.com/github/promptworks/logging_elf/badges/gpa.svg)](https://codeclimate.com/github/promptworks/logging_elf)
[![Dependency Status](https://gemnasium.com/promptworks/logging_elf.svg)](https://gemnasium.com/promptworks/logging_elf)

## Overview
Logging in Rails is not well-suited for large applications for a few reasons:
* The built-in logging is string-based, a limitation of the default ruby logger (as opposed to the more powerful, if confusing, log4* frameworks)
* Rails' internals performs some logging that isn't especially flexible
* When your application has a number of tiers operating across multiple processes, languages and/or machines, there isn't a good way to tie the logging messages across all of the different tiers (tracing/barium meals)

LoggingElf is a gem we extracted (poorly, if I'm being honest) that ties together several other gems in an effort to solve the above problems.

The pieces / gems we've cobbled together include:

### logging

A log4* clone that seems to be more maintained than log4r.  This gives you the ability to very carefully your logging data along each of these vertices independently:
    
    * Format - It permits string-based formatting of course. Even the built-in logger does that.

    * Destination (Appenders) - The real power in log4* has to do with the ability to write log messages to multiple destinations simultaneously, in formats that make sense for them. We're using this to log metadata-rich messages to graylog, so that we can slice and dice the data using it's search capabilities. But because of the different appenders and formatters, we can still write the same data to a string format for local log files

    * Importance - We can write out only errors to std out, but include all of the detail when logging to a file.  Each appender can filter messages based on the log level of the message

### GELF

The GELF is a data format accepted by graylog (and other sophisticated logging engines, like logstash).  It lets you send log messages that haven't been smashed into a string, so that each attribute can be independently indexed and used to find log information faster.

GELF is actually a data standard, and so we've created a Virtus model that represents it, using ActiveModel validations to enforce its conventions. 

### Virtus and ActiveModel

See GELF, to understand why these gems are required.

### Lograge

<a href="https://github.com/roidrage/lograge" target="_blank">Lograge</a> isn't a required gem. We have been using it to reduce the chattiness of Rails' default logging.  However, in order for it to play well with the GELF data format, we needed to tweak the data it sends to the logger.  (See lograge_formatter)

### Tracing

As powerful as the logging gem is, its configuration was never meant to let you configure what was logged.  It doesn't take over until the log message has been crafted.

So tracing doesn't build upon any particular gem. The idea with tracing is that tracing data should not have to be explicitly included in each log message. What is in the trace is orthogonal to what is being logged.  

For example, when a new request comes in, we assign it a request_id, which is just a guid, that gets added to the trace hash.  The users's session_id goes in with it. As a result, any log message that is fired from our rails app can be tied directly to a particular session or request. If 2 suspicious log messages come in at the same time, we can know for sure whether they are for the same request, or at least for the same user. This feature lets you effectively flip your logging data in such a way that it's no longer just a stream of temporal data. Now you can index it by user.  If you include the path of the request, you could index it by what portion of your application it hits. 

We've done this with TracingLogger, which lets the user provide a trace_hash of data (or a proc that returns a trace hash) during initialization. Then any message that comes in is augmented with that data before being sent along the normal logging path that was configured.

## Installation

Add this line to your application's Gemfile:

    gem 'logging_elf'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logging_elf

## Usage

### Tracing

*Configuration*

```ruby
LoggingElf.configure do |config|
    config.trace_hash = -> { 
        # Your code goes here. For our web app, we've been happily 
        # using Steve Klabnik's https://github.com/steveklabnik/request_store 
        # to set trace data in the application controller, and then reference
        # it here with:
        RequestStore.store[:trace]
    }
end
```

You can then set the rails logger like this:

```ruby
::Rails.logger = LoggingElf::TracingLogger.new("rails")
```

If you'd like to override the ActionController and ActionMailer loggers that Rails uses internally:

```ruby
ActionController::Base.logger =
  LoggingElf::TracingLogger.new("action_controller")
ActionMailer::Base.logger = LoggingElf::TracingLogger.new("action_mailer")
ActionView::Base.logger = LoggingElf::TracingLogger.new("action_view")
```

*NOTE:* You probably don't want to do this if you are not also using Lograge, because you'll be dumping a lot of data into Rails' small, super-chatty log statements.

*TODO:* Figure out why lograge is not turning off the ActionView logger

### Lograge

One unfortunate side-effect of the string-based approach to logging that rails employs appears to be that the default log messages are very chatty.  I'll leave it to <a href="https://github.com/roidrage/lograge" target="_blank">Lograge</a> to explain why that can be annoying. But the short version is that using lograge aggregates multiple log messages from rails into fewer, more useful messages that you probably want to hold on to. Lograge isn't actually a logger.  What it does is unhook the default logging, and hook itself in instead.  It then collects the events, aggregates them, and then forwards them along to whatever the configured logger is.

After adding lograge to your Gemfile, you can configure this in an initializer like so:

```ruby
YOURAPP::Application.configure do
    config.lograge.enabled = true
    config.lograge.formatter = LoggingElf::LogrageFormatter.new
end
```

The formatter is just for the ActionController's log message, and is only important for GELF data.  It sets the path of the request to the short_message property of the GELF object.

### GELF
The Gelf gem includes a logger, but it is not compatible with the logging gem. (It merges the concept of log message writing and formatting).  So we've created a GelfAppender that fits the paradigm.

```ruby
LoggingElf.configure do |config|
    config.graylog_host = "WHATEVER"
    config.graylog_port = "WHATEVER"
end
LoggingElf.appenders.gelf
# Of course, you probably want more appenders than just these...
Logging.logger.root.appenders = ["gelf"]
```


## Contributing

1. Fork it ( https://github.com/[my-github-username]/logging_elf/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
