// We just need a way to build a test binary or just compile the script using `swiftc` linking against the app/framework, but unfortunately `swiftc` alone doesn't easily link against Xcode targets with UI constraints without XCTest.
// Instead, let's create a quick XCTest case inside a new test file, but Wait! It's much easier to just create a command line tool target? No, better yet, we can create a simple ruby script to inject a test into AppDelegate's `didFinishLaunchingWithOptions`, then launch the app in the simulator and read its logs.

