# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
not_declared_trivial = !(github.pr_title.include? "#trivial")
has_app_changes = !git.modified_files.grep(/Sources/).empty?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "WIP"

# Warn when there is a big PR
warn("Big PR, try to keep changes smaller if you can") if git.lines_of_code > 500

# Warn when library files has been updated but not tests.
tests_updated = !git.modified_files.grep(/Tests/).empty?
if has_app_changes && !tests_updated
  warn("The library files were changed, but the tests remained unmodified. Consider updating or adding to the tests to match the library changes.")
end

# Run SwiftLint
swiftlint.lint_files

# Run prose
prose.ignored_words = ["SPM", "CFBundleVersion", "JobInfo", "compactMap", "lastError", "args", "enum", "SwiftQueue", "JobBuilder", "SwiftQueueManager", "onError", "carthage", "Rechability", "Cleanup", "TimeInterval", "SingleInstance", "Swiftlint", "travis", "params", "JobCompletion", "inSecond", "onRetry", "onRemove", "UniqueUUID", "OperationQueue", "SwiftQueueJob", "uuid", "DEPS", "serializer", "deserialization", "Deserialize"]
prose.ignore_numbers = true
prose.check_spelling
