# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## UNRELEASED

## [1.8.3] - 2019-09-24
- Version bump for official release.

## [1.8.2-beta2] - 2019-06-21
- Added the `persistent_connections` setting and the corresponding
  `sync_producer_shutdown` method to enable reusing the connection
  for regular (sync) producers.

## [1.8.2-beta1] - 2019-03-13

- Added `BatchHandler` to consume messages in batches on the business
  layer.

## [1.8.1] - 2018-11-23
### Added
- Added ability to send partition keys separate from messsage keys.

## [1.8.0] - 2018-07-22
### Added
- Possibility to configure a custom logger #81
### Changed
- Reduce the volume of info-level log messages #78
- Phobos Handler `around_consume` is now an instance method #82
- Send consumer heartbeats between retry attempts #83

## [1.7.2] - 2018-05-03
### Added
- Add ability to override session_timeout, heartbeat_interval, offset_retention_time, offset_commit_interval, and offset_commit_threshold per listener
### Changed
- Phobos CLI: Load boot file before configuring (instead of after)

## [1.7.1] - 2018-02-22
### Fixed
- Phobos overwrites ENV['RAILS_ENV'] with incorrect value #71
- Possible NoMethodError #force_encoding #63
- Phobos fails silently #66
### Added
- Add offset_retention_time to consumer options #62

## [1.7.0] - 2017-12-05
### Fixed
- Test are failing with ruby-kafka 0.5.0 #48
- Allow Phobos to run in apps using ActiveSupport 3.x #57
### Added
- Property (handler) added to listener instrumentation #60
### Removed
- Property (time_elapsed) removed - use duration instead #24
### Changed
- Max bytes per partition is now 1 MB by default #56

## [1.6.1] - 2017-11-16
### Fixed
- `Phobos::Test::Helper` is broken #53

## [1.6.0] - 2017-11-16
### Added
- Support for outputting logs as json #50
- Make configuration, especially of listeners, more flexible. #31
- Phobos Discord chat
- Support for consuming `each_message` instead of `each_batch` via the delivery listener option. #21
- Instantiate a single handler class instance and use that both for `consume` and `before_consume`. #47

### Changed
- Pin ruby-kafka version to < 0.5.0 #48
- Update changelog to follow the [Keep a Changelog](http://keepachangelog.com/) structure

## [1.5.0] - 2017-10-25
### Added
- Add `before_consume` callback to support single point of decoding a message klarna/phobos_db_checkpoint#34
- Add `Phobos::Test::Helper` for testing, to test consumers with minimal setup required

### Changed
- Allow configuration of backoff per listener #35
- Move container orchestration into docker-compose
- Update docker images #38

### Fixed
- Make specs run locally #36

## [1.4.2] - 2017-09-29
### Fixed
- Async publishing always delivers messages #33

## [1.4.1] - 2017-08-22
### Added
- Update dev dependencies to fix warnings for the new unified Integer class

### Fixed
- Include the error `Kafka::ProcessingError` into the abort block

## [1.4.0] - 2017-08-21
### Added
- Support for hash provided settings #30

## [1.3.0] - 2017-06-15
### Added
- Support for ERB syntax in Phobos config file #26

## [1.2.1] - 2016-10-12
### Fixed
- Ensure JSON layout for log files

## [1.2.0] - 2016-10-10
### Added
- Log file can be disabled #20
- Property (time_elapsed) available for notifications `listener.process_message` and `listener.process_batch` #24
- Option to configure ruby-kafka logger #23

## [1.1.0] - 2016-09-02
### Added
- Removed Hashie as a dependency #12
- Allow configuring consumers min_bytes & max_wait_time #15
- Allow configuring producers max_queue_size, delivery_threshold & delivery_interval #16
- Allow configuring force_encoding for message payload #18

## [1.0.0] - 2016-08-08
### Added
- Published on Github!
