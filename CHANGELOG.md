# Change Log

## [v1.4.1](https://github.com/lucas34/SwiftQueue/tree/1.4.1)

#### Bug fix 
- Fix an issue where a periodic job with unlimited run will not be re-scheduled #63
- Validate dictionary args only if persistence is required (#61)

#### Other changes
- Make unavailable crash if called #64
- Raise warning if something went wrong during the deserialization (#58)

## [v1.4.0](https://github.com/lucas34/SwiftQueue/tree/1.4.0)

Develop 1.4.0 (#52)

#### Breaking changes
- Validate argument to avoid empty strings
- Validate JSON argument

#### Create Limit enum
- JobBuilder.retry(Limit)
- JobBuilder.periodic(Limit, TimeInterval)

## [v1.3.2](https://github.com/lucas34/SwiftQueue/tree/1.3.2)

#### New features
- Allow overriding previous job for SingleInstance constraint (#38)
- Add cancel with uuid (#42)

#### Bug fix and improvements
- Fix Swiftlint warnings (#36)
- Fix readme documentation (#40)

#### Misc
- Setup danger (#31)
- Support travis cache builds (#39)

## [v1.3.1](https://github.com/lucas34/SwiftQueue/tree/1.3.1)

- Fix crash in exponential retry
- Fix exponential retry not reset after a success run

## [v1.3.0](https://github.com/lucas34/SwiftQueue/tree/1.3.0)
Develop 1.3.0 Re-write 90% of the code (#22) 

#### Breaking changes 
- Scheduling a job without a creator will throw an error (Assertion) 
- Replace Any params type to [String: Any] (#20) 
- Callback result now use enum to avoid passing nil error as success (#26) 
- onRemove will foward JobCompletion (#32)
- Remove delay(inSecond) use delay(time) instead 

#### Bug fix and improvements 
- Improve documentation and publish (#24) 
- Constraints should be public (#25) 
- Add assertion to validate the [String: Any] when serialise 

## [v1.2.3](https://github.com/lucas34/SwiftQueue/tree/1.2.3)

- Job is now immediately canceled when the deadline is reached

## [v1.2.2](https://github.com/lucas34/SwiftQueue/tree/1.2.2)

- Add support for Swift Package Manager

## [v1.2.1](https://github.com/lucas34/SwiftQueue/tree/1.2.1)

- Fix job retain loger after cancellation

## [v1.2.0](https://github.com/lucas34/SwiftQueue/tree/1.2.0)

#### Bug Fix
- Job constraint error should not call onRetry
- if Reachability throw error when starting the notifier, call onRemove
- UniqueUUID constraint will also be checked for same name in non SwiftQueueJob
- Fix retention issue

#### Project structure Changes
- Each constraints will be defined in it's own file
- Each job will own an instance of all the constrains

#### Breaking changes
- Remove throw in Run method to avoid confusion with onError callback
- User will need to keep a strong reference to SwiftQueueManager

## [v1.1.0](https://github.com/lucas34/SwiftQueue/tree/1.1.0)

#### Carthage
Support all targets when using carthage

#### New
- Delay by TimeInterval

#### Improvement
- Reschedule and run immediately when delay set to 0 

#### Bug fix
- Job not delayed properly
- Crash when delaying the job with a huge number

## [v1.0.1](https://github.com/lucas34/SwiftQueue/tree/1.0.1)

#### Breaking changes
- Add delay to retry()
- Pause and restart will match behaviour of OperationQueue to avoid job running 2 times

## [v1.0.0](https://github.com/lucas34/SwiftQueue/tree/1.0.0)

- First stable release