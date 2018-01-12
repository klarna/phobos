![Phobos](https://raw.githubusercontent.com/klarna/phobos/master/logo.png)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fklarna%2Fphobos.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fklarna%2Fphobos?ref=badge_shield)

[![Build Status](https://travis-ci.org/klarna/phobos.svg?branch=master)](https://travis-ci.org/klarna/phobos)
[![Maintainability](https://api.codeclimate.com/v1/badges/2d00845fc6e7e83df6e7/maintainability)](https://codeclimate.com/github/klarna/phobos/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/2d00845fc6e7e83df6e7/test_coverage)](https://codeclimate.com/github/klarna/phobos/test_coverage)
[![Chat with us on Discord](https://discordapp.com/api/guilds/379938130326847488/widget.png)](https://discord.gg/rfMUBVD)

# Phobos

Simplifying Kafka for Ruby apps!

Phobos is a micro framework and library for applications dealing with [Apache Kafka](http://kafka.apache.org/).

- It wraps common behaviors needed by consumers and producers in an easy and convenient API
- It uses [ruby-kafka](https://github.com/zendesk/ruby-kafka) as its Kafka client and core component
- It provides a CLI for starting and stopping a standalone application ready to be used for production purposes

Why Phobos? Why not `ruby-kafka` directly? Well, `ruby-kafka` is just a client. You still need to write a lot of code to manage proper consuming and producing of messages. You need to do proper message routing, error handling, retrying, backing off and maybe logging/instrumenting the message management process. You also need to worry about setting up a platform independent test environment that works on CI as well as any local machine, and even on your deployment pipeline. Finally, you also need to consider how to deploy your app and how to start it.

With Phobos by your side, all this becomes smooth sailing.

## Table of Contents

1. [Installation](#installation)
1. [Usage](#usage)
  1. [Standalone apps](#usage-standalone-apps)
  1. [Consuming messages from Kafka](#usage-consuming-messages-from-kafka)
  1. [Producing messages to Kafka](#usage-producing-messages-to-kafka)
  1. [As library in another app](#usage-as-library)
  1. [Configuration file](#usage-configuration-file)
  1. [Instrumentation](#usage-instrumentation)
1. [Plugins](#plugins)
1. [Development](#development)
1. [Test](#test)

## <a name="installation"></a> Installation

Add this line to your application's Gemfile:

```ruby
gem 'phobos'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install phobos
```

## <a name="usage"></a> Usage

Phobos can be used in two ways: as a standalone application or to support Kafka features in your existing project - including Rails apps. It provides a CLI tool to run it.

### <a name="usage-standalone-apps"></a> Standalone apps

Standalone apps have benefits such as individual deploys and smaller code bases. If consuming from Kafka is your version of microservices, Phobos can be of great help.

### Setup

To create an application with Phobos you need two things:
  * A configuration file (more details in the [Configuration file](#usage-configuration-file) section)
  * A `phobos_boot.rb` (or the name of your choice) to properly load your code into Phobos executor

Use the Phobos CLI command __init__ to bootstrap your application. Example:

```sh
# call this command inside your app folder
$ phobos init
    create  config/phobos.yml
    create  phobos_boot.rb
```

`phobos.yml` is the configuration file and `phobos_boot.rb` is the place to load your code.

### Consumers (listeners and handlers)

In Phobos apps __listeners__ are configured against Kafka - they are our consumers. A listener requires a __handler__ (a ruby class where you should process incoming messages), a Kafka __topic__, and a Kafka __group_id__. Consumer groups are used to coordinate the listeners across machines. We write the __handlers__ and Phobos makes sure to run them for us. An example of a handler is:

```ruby
class MyHandler
  include Phobos::Handler

  def consume(payload, metadata)
    # payload  - This is the content of your Kafka message, Phobos does not attempt to
    #            parse this content, it is delivered raw to you
    # metadata - A hash with useful information about this event, it contains: The event key,
    #            partition number, offset, retry_count, topic, group_id, and listener_id
  end
end
```

Writing a handler is all you need to allow Phobos to work - it will take care of execution, retries and concurrency.

To start Phobos the __start__ command is used, example:

```sh
$ phobos start
[2016-08-13T17:29:59:218+0200Z] INFO  -- Phobos : <Hash> {:message=>"Phobos configured", :env=>"development"}
______ _           _
| ___ \ |         | |
| |_/ / |__   ___ | |__   ___  ___
|  __/| '_ \ / _ \| '_ \ / _ \/ __|
| |   | | | | (_) | |_) | (_) \__ \
\_|   |_| |_|\___/|_.__/ \___/|___/

phobos_boot.rb - find this file at ~/Projects/example/phobos_boot.rb

[2016-08-13T17:29:59:272+0200Z] INFO  -- Phobos : <Hash> {:message=>"Listener started", :listener_id=>"6d5d2c", :group_id=>"test-1", :topic=>"test"}
```

By default, the __start__ command will look for the configuration file at `config/phobos.yml` and it will load the file `phobos_boot.rb` if it exists. In the example above all example files generated by the __init__ command are used as is. It is possible to change both files, use `-c` for the configuration file and `-b` for the boot file. Example:

```sh
$ phobos start -c /var/configs/my.yml -b /opt/apps/boot.rb
```

You may also choose to configure phobos with a hash from within your boot file.
In this case, disable loading the config file with the `--skip-config` option:

```sh
$ phobos start -b /opt/apps/boot.rb --skip-config
```

### <a name="usage-consuming-messages-from-kafka"></a> Consuming messages from Kafka

Messages from Kafka are consumed using __handlers__. You can use Phobos __executors__ or include it in your own project [as a library](#usage-as-library), but __handlers__ will always be used. To create a handler class, simply include the module `Phobos::Handler`. This module allows Phobos to manage the life cycle of your handler.

A handler is required to implement the method `#consume(payload, metadata)`.

Instances of your handler will be created for every message, so keep a constructor without arguments. If `consume` raises an exception, Phobos will retry the message indefinitely, applying the back off configuration presented in the configuration file. The `metadata` hash will contain a key called `retry_count` with the current number of retries for this message. To skip a message, simply return from `#consume`.

When the listener starts, the class method `.start` will be called with the `kafka_client` used by the listener. Use this hook as a chance to setup necessary code for your handler. The class method `.stop` will be called during listener shutdown.

```ruby
class MyHandler
  include Phobos::Handler

  def self.start(kafka_client)
    # setup handler
  end

  def self.stop
    # teardown
  end

  def consume(payload, metadata)
    # consume or skip message
  end
end
```

It is also possible to control the execution of `#consume` with the class method `.around_consume(payload, metadata)`. This method receives the payload and metadata, and then invokes `#consume` method by means of a block; example:

```ruby
class MyHandler
  include Phobos::Handler

  def self.around_consume(payload, metadata)
    Phobos.logger.info "consuming..."
    output = yield
    Phobos.logger.info "done, output: #{output}"
  end

  def consume(payload, metadata)
    # consume or skip message
  end
end
```

Finally, it is also possible to preprocess the message payload before consuming it using the `before_consume` hook which is invoked before `.around_consume` and `#consume`. The result of this operation will be assigned to payload, so it is important to return the modified payload. This can be very useful, for example if you want a single point of decoding Avro messages and want the payload as a hash instead of a binary.

```ruby
class MyHandler
  include Phobos::Handler

  def before_consume(payload)
    # optionally preprocess payload
    payload
  end
end
```

Take a look at the examples folder for some ideas.

The hander life cycle can be illustrated as:

  `.start` -> `#consume` -> `.stop`

or optionally,

  `.start` -> `#before_consume` -> `.around_consume` [ `#consume` ] -> `.stop`

### <a name="usage-producing-messages-to-kafka"></a> Producing messages to Kafka

`ruby-kafka` provides several options for publishing messages, Phobos offers them through the module `Phobos::Producer`. It is possible to turn any ruby class into a producer (including your handlers), just include the producer module, example:

```ruby
class MyProducer
  include Phobos::Producer
end
```

Phobos is designed for multi threading, thus the producer is always bound to the current thread. It is possible to publish messages from objects and classes, pick the option that suits your code better.
The producer module doesn't pollute your classes with a thousand methods, it includes a single method the class and in the instance level: `producer`.

```ruby
my = MyProducer.new
my.producer.publish('topic', 'message-payload', 'partition and message key')

# The code above has the same effect of this code:
MyProducer.producer.publish('topic', 'message-payload', 'partition and message key')
```

It is also possible to publish several messages at once:

```ruby
MyProducer
  .producer
  .publish_list([
    { topic: 'A', payload: 'message-1', key: '1' },
    { topic: 'B', payload: 'message-2', key: '2' },
    { topic: 'B', payload: 'message-3', key: '3' }
  ])
```

There are two flavors of producers: __regular__ producers and __async__ producers.

Regular producers will deliver the messages synchronously and disconnect, it doesn't matter if you use `publish` or `publish_list` after the messages get delivered the producer will disconnect.

Async producers will accept your messages without blocking, use the methods `async_publish` and `async_publish_list` to use async producers.

An example of using handlers to publish messages:

```ruby
class MyHandler
  include Phobos::Handler
  include Phobos::Producer

  PUBLISH_TO = 'topic2'

  def consume(payload, metadata)
    producer.async_publish(PUBLISH_TO, {key: 'value'}.to_json)
  end
end
```

#### Note about configuring producers

Since the handler life cycle is managed by the Listener, it will make sure the producer is properly closed before it stops. When calling the producer outside a handler remember, you need to shutdown them manually before you close the application. Use the class method `async_producer_shutdown` to safely shutdown the producer.

Without configuring the Kafka client, the producers will create a new one when needed (once per thread). To disconnect from kafka call `kafka_client.close`.

```ruby
# This method will block until everything is safely closed
MyProducer
  .producer
  .async_producer_shutdown

MyProducer
  .producer
  .kafka_client
  .close
```

### <a name="usage-as-library"></a> Phobos as a library in an existing project

When running as a standalone service, Phobos sets up a `Listener` and `Executor` for you. When you use Phobos as a library in your own project, you need to set these components up yourself.

First, call the method `configure` with the path of your configuration file or with configuration settings hash.

```ruby
Phobos.configure('config/phobos.yml')
```
or
```ruby
Phobos.configure(kafka: { client_id: 'phobos' }, logger: { file: 'log/phobos.log' })
```

__Listener__ connects to Kafka and acts as your consumer. To create a listener you need a handler class, a topic, and a group id.

```ruby
listener = Phobos::Listener.new(
  handler: Phobos::EchoHandler,
  group_id: 'group1',
  topic: 'test'
)

# start method blocks
Thread.new { listener.start }

listener.id # 6d5d2c (all listeners have an id)
listener.stop # stop doesn't block
```

This is all you need to consume from Kafka with back off retries.

An __executor__ is the supervisor of all listeners. It loads all listeners configured in `phobos.yml`. The executor keeps the listeners running and restarts them when needed.

```ruby
executor = Phobos::Executor.new

# start doesn't block
executor.start

# stop will block until all listers are properly stopped
executor.stop
```

When using Phobos __executors__ you don't care about how listeners are created, just provide the configuration under the `listeners` section in the configuration file and you are good to go.

### <a name="usage-configuration-file"></a> Configuration file
The configuration file is organized in 6 sections. Take a look at the example file, [config/phobos.yml.example](https://github.com/klarna/phobos/blob/master/config/phobos.yml.example).

The file will be parsed through ERB so ERB syntax/file extension is supported beside the YML format.

__logger__ configures the logger for all Phobos components, it automatically outputs to `STDOUT` and it saves the log in the configured file

__kafka__ provides configurations for every `Kafka::Client` created over the application. All [options supported by  `ruby-kafka`][ruby-kafka-client] can be provided.

__producer__ provides configurations for all producers created over the application, the options are the same for regular and async producers. All [options supported by  `ruby-kafka`][ruby-kafka-producer] can be provided.

__consumer__ provides configurations for all consumer groups created over the application. All [options supported by  `ruby-kafka`][ruby-kafka-consumer] can be provided.

__backoff__ Phobos provides automatic retries for your handlers, if an exception is raised the listener will retry following the back off configured here. Backoff can also be configured per listener.

__listeners__ is the list of listeners configured, each listener represents a consumers group

[ruby-kafka-client]: http://www.rubydoc.info/gems/ruby-kafka/Kafka%2FClient%3Ainitialize
[ruby-kafka-consumer]: http://www.rubydoc.info/gems/ruby-kafka/Kafka%2FClient%3Aconsumer
[ruby-kafka-producer]: http://www.rubydoc.info/gems/ruby-kafka/Kafka%2FClient%3Aproducer

#### Additional listener configuration

In some cases it's useful to  share _most_ of the configuration between
multiple phobos processes, but have each process run different listeners. In
that case, a separate yaml file can be created and loaded with the `-l` flag.
Example:

```sh
$ phobos start -c /var/configs/my.yml -l /var/configs/additional_listeners.yml
```

Note that the config file _must_ still specify a listeners section, though it
can be empty.

### <a name="usage-instrumentation"></a> Instrumentation

Some operations are instrumented using [Active Support Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html).

In order to receive notifications you can use the module `Phobos::Instrumentation`, example:

```ruby
Phobos::Instrumentation.subscribe('listener.start') do |event|
  puts(event.payload)
end
```

`Phobos::Instrumentation` is a convenience module around `ActiveSupport::Notifications`, feel free to use it or not. All Phobos events are in the `phobos` namespace. `Phobos::Instrumentation` will always look at `phobos.` events.

#### Executor notifications
  * `executor.retry_listener_error` is sent when the listener crashes and the executor wait for a restart. It includes the following payload:
    * listener_id
    * retry_count
    * waiting_time
    * exception_class
    * exception_message
    * backtrace
  * `executor.stop` is sent when executor stops

#### Listener notifications
  * `listener.start_handler` is sent when invoking `handler.start(kafka_client)`. It includes the following payload:
    * listener_id
    * group_id
    * topic
    * handler
  * `listener.start` is sent when listener starts. It includes the following payload:
    * listener_id
    * group_id
    * topic
    * handler
  * `listener.process_batch` is sent after process a batch. It includes the following payload:
    * listener_id
    * group_id
    * topic
    * handler
    * batch_size
    * partition
    * offset_lag
    * highwater_mark_offset
  * `listener.process_message` is sent after process a message. It includes the following payload:
    * listener_id
    * group_id
    * topic
    * handler
    * key
    * partition
    * offset
    * retry_count
  * `listener.retry_handler_error` is sent after waited for `handler#consume` retry. It includes the following payload:
    * listener_id
    * group_id
    * topic
    * handler
    * key
    * partition
    * offset
    * retry_count
    * waiting_time
    * exception_class
    * exception_message
    * backtrace
  * `listener.retry_aborted` is sent after waiting for a retry but the listener was stopped before the retry happened. It includes the following payload:
    * listener_id
    * group_id
    * topic
    * handler
  * `listener.stopping` is sent when the listener receives signal to stop
    * listener_id
    * group_id
    * topic
    * handler
  * `listener.stop_handler` is sent after stopping the handler
    * listener_id
    * group_id
    * topic
    * handler
  * `listener.stop` is send after stopping the listener
    * listener_id
    * group_id
    * topic
    * handler

## <a name="plugins"></a> Plugins

List of gems that enhance Phobos:

* [Phobos DB Checkpoint](https://github.com/klarna/phobos_db_checkpoint) is drop in replacement to Phobos::Handler, extending it with the following features:
  * Persists your Kafka events to an active record compatible database
  * Ensures that your handler will consume messages only once
  * Allows your system to quickly reprocess events in case of failures

* [Phobos Checkpoint UI](https://github.com/klarna/phobos_checkpoint_ui) gives your Phobos DB Checkpoint powered app a web gui with the features below. Maintaining a Kafka consumer app has never been smoother:
  * Search events and inspect payload
  * See failures and retry / delete them

* [Phobos Prometheus](https://github.com/phobos/phobos_prometheus) adds prometheus metrics to your phobos consumer.
  * Measures total messages and batches processed
  * Measures total duration needed to process each message (and batch)
  * Adds `/metrics` endpoit to scrape data

## <a name="development"></a> Development

After checking out the repo:
* make sure `docker` is installed and running (for windows and mac this also includes `docker-compose`).
* Linux: make sure `docker-compose` is installed and running.
* run `bin/setup` to install dependencies
* run `docker-compose up` to start the required kafka containers in a window
* run `rspec` to run the tests in another window

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## <a name="test"></a> Test

Phobos exports a spec helper that can help you test your consumer. The Phobos lifecycle will conveniently be activated for you with minimal setup required.

* `process_message(handler:, payload:, metadata: {}, encoding: nil)` - Invokes your handler with payload and metadata, using a dummy listener (encoding and metadata are optional).

```ruby
require 'spec_helper'

describe MyConsumer do
  let(:payload) { 'foo' }
  let(:metadata) { Hash(foo: 'bar') }

  it 'consumes my message' do
    expect(described_class).to receive(:around_consume).with(payload, metadata).once.and_call_original
    expect_any_instance_of(described_class).to receive(:before_consume).with(payload).once.and_call_original
    expect_any_instance_of(described_class).to receive(:consume).with(payload, metadata).once.and_call_original

    process_message(handler: described_class, payload: payload, metadata: metadata)
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/klarna/phobos.

## Acknowledgements

Thanks to Sebastian Norde for the awesome logo!

## License

Copyright 2016 Klarna

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.

You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fklarna%2Fphobos.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fklarna%2Fphobos?ref=badge_large)