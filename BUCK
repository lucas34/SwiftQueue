#####################################
# Defines
#####################################

COMMON_PREPROCESSOR_FLAGS = [
  '-fobjc-arc',
  '-DDEBUG=1',
]

SWIFTQUEUE_HEADER = 'Sources/SwiftQueue.h'

#####################################
# SwiftQueue binaries
#####################################

apple_library(
  name = 'SwiftQueue',
  visibility = ['PUBLIC'],
  bridging_header = SWIFTQUEUE_HEADER,
  exported_headers = [SWIFTQUEUE_HEADER],
  preprocessor_flags = COMMON_PREPROCESSOR_FLAGS,
  srcs = glob([
    'Sources/**/*.swift',
  ]),
  tests = [ ':SwiftQueueTests' ],
  frameworks = [
    '$SDKROOT/System/Library/Frameworks/Foundation.framework',
    ':Reachability',
  ],
)

prebuilt_apple_framework(
    name = 'Reachability',
    preferred_linkage = 'shared',
    framework = 'Carthage/Build/iOS/Reachability.framework',
)

#####################################
# SwiftQueue tests
#####################################

apple_test(
  name = 'SwiftQueueTests',
  info_plist = 'Tests/SwiftQueueTests/Info.plist',
  info_plist_substitutions = {
    'PRODUCT_BUNDLE_IDENTIFIER': 'SwiftQueue',
  },
  srcs = glob([
      'Tests/**/*.swift'
  ], exclude = ['Tests/SwiftQueueTests/SwiftQueueBuilderTests.swift'] ),
  deps = [
    ':Reachability',
    ':SwiftQueue',
  ],
    preprocessor_flags = COMMON_PREPROCESSOR_FLAGS + [
    '-Wno-implicit-function-declaration',
    '-Wno-deprecated-declarations',
  ],
  frameworks = [
    '$SDKROOT/System/Library/Frameworks/Foundation.framework',
    '$PLATFORM_DIR/Developer/Library/Frameworks/XCTest.framework',
  ],
)