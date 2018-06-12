# Change Log

## [2.1.0](https://github.com/lucas34/SwiftQueue/tree/2.1.0)

#### Breaking Changes
- Remove deprecated methods (#156)

#### Fix
- Prevent missing CFBundleVersion (#153)

## [2.0.0](https://github.com/lucas34/SwiftQueue/tree/2.0.0)

#### Breaking Changes
- `SwiftQueueManager` need to be built with `SwiftQueueManagerBuilder` (#126)  
- Custom serializer and switch to `codable` by default (#115)
- Minimum version required is `Swift 3.2`
- Add a persister by default to avoid having `persist(required: true)` but no `persister` (#119)

#### Improvement
- Expose `isSuspended` from `SwiftQueueManager` (#145)
- Revise JobInfo and make it conform to `Codable` protocol (#117) (#120)

#### New features
- Charging constraint (#123) 
- Deserialize tasks in background (#112)
- Add internal logger (#105)

Cleanup JobInfo structure 

#### Fix 
- Fix constraint does not properly cancel the job and execution flow should stop (#113)
- Execution flow does not stop immediately after a constraint not satisfied (#113)
- Parsing error not forwarded and not reported with the logger (#121)
- Parsing error not reported and prevent the job to be serialized (#122)

#### MISC
- Update for Swift 3.3 and 4.1 (#110) (#111) (#107)
- Add proper implementation of support compactMap (#116)

## [1.6.1](https://github.com/lucas34/SwiftQueue/tree/1.6.1)

#### Improvement
- Fix compatibility with Swift 3.2 (#100) 
- Fix warning for Swift 4.1 (#102)

## [1.6.0](https://github.com/lucas34/SwiftQueue/tree/1.6.0)

#### Breaking Changes
- Change `JobCreator.create` signature (#94)
    - Return type is no longer optional
    - `SwiftQueueManager` only accept 1 single `JobCreator`
    - This is to avoid unregistered handler or scheduling job with no `JobCreator` associates
    - The user will have to deal with unknown handler on his side
- Origin error is now forward to completion block (#88)
- Change signature of Limit(Int) to Limit(Double)

#### Fix 
- Delay not waiting for the remaining time (#99)
- Deadline now cancel the job properly (#98)
- Fix calling `done` after termination will remove the lastError (#97)
- Breaking support for Swift 3.2 (#75)

#### Improvement
- Avoid crash when scheduling a terminated job (#92)
- Performance issue when overriding a job (#73)

#### Misc
- Update documentation

## [1.5.0](https://github.com/lucas34/SwiftQueue/tree/1.5.0)

#### Breaking Changes
- Change Error type to follow enum pattern (#68) 
    - `TaskAlreadyExist` -> `SwiftQueueError.Duplicate`
    - `DeadlineError` -> `SwiftQueueError.Deadline`
    - `Canceled` -> `SwiftQueueError.Canceled`

#### Improvement
- Performance improvement in for-loops

#### Internal changes
- `SwiftQueue` has been renamed `SqOperationQueue`
- `SwiftQueueJob` -> `SqOperation`
- `JobBuilder` has moved to its own class
- SwiftQueue.swift reference all public protocols

#### Misc
- Support `BUCK` build

#### Other changes
- Remove unavailable methods (#71)
    - `func retry(Int)`
    - `func periodic(Int, TimeInterval)`

## [1.4.1](https://github.com/lucas34/SwiftQueue/tree/1.4.1)

#### Bug fix 
- Fix an issue where a periodic job will not be re-scheduled (#63)
- Validate dictionary args only if persistence is required (#61)

#### Other changes
- Make unavailable methods crash if called #64
- Raise warning if something went wrong during the deserialization (#58)

## [1.4.0](https://github.com/lucas34/SwiftQueue/tree/1.4.0)

Develop 1.4.0 (#52)

#### Breaking changes
- Validate argument to avoid empty strings
- Validate JSON argument

#### Create Limit enum
- JobBuilder.retry(Limit)
- JobBuilder.periodic(Limit, TimeInterval)

## [1.3.2](https://github.com/lucas34/SwiftQueue/tree/1.3.2)

#### New features
- Allow overriding previous job for SingleInstance constraint (#38)
- Add cancel with uuid (#42)

#### Bug fix and improvements
- Fix Swiftlint warnings (#36)
- Fix readme documentation (#40)

#### Misc
- Setup danger (#31)
- Support travis cache builds (#39)

## [1.3.1](https://github.com/lucas34/SwiftQueue/tree/1.3.1)

- Fix crash in exponential retry
- Fix exponential retry not reset after a success run

## [1.3.0](https://github.com/lucas34/SwiftQueue/tree/1.3.0)
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
- Add assertion to validate the [String: Any] when serialize

## [1.2.3](https://github.com/lucas34/SwiftQueue/tree/1.2.3)

- Job is now immediately canceled when the deadline is reached

## [1.2.2](https://github.com/lucas34/SwiftQueue/tree/1.2.2)

- Add support for Swift Package Manager

## [1.2.1](https://github.com/lucas34/SwiftQueue/tree/1.2.1)

- Fix job retained longer after cancellation

## [1.2.0](https://github.com/lucas34/SwiftQueue/tree/1.2.0)

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

## [1.1.0](https://github.com/lucas34/SwiftQueue/tree/1.1.0)

#### Carthage
Support all targets when using carthage

#### New
- Delay by TimeInterval

#### Improvement
- Reschedule and run immediately when delay is set to 0

#### Bug fix
- Job not delayed properly
- Crash when delaying the job with a high value

## [1.0.1](https://github.com/lucas34/SwiftQueue/tree/1.0.1)

#### Breaking changes
- Add delay to retry()
- Pause and restart will match behaviour of OperationQueue to avoid job running 2 times

## [1.0.0](https://github.com/lucas34/SwiftQueue/tree/1.0.0)

- First stable release
