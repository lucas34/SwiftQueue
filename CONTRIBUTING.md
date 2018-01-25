### Development Process

`master` is for release, hot fix and non source code changes such as documentation.

`development` is for the next release. This branch should be targetted for breaking changes.

### Merging

All Pull requests will be merged with a `rebased squash merge`.
For a new release, create a Pull request from `development` to `master`.

### Submitting pull request
Pull request should be discussed first. So please create an issue before submitting any Pull request. 

### Testing
Please test your changes before submitting your pull request. You can run the command `swift test`
