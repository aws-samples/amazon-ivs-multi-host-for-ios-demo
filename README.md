# Amazon IVS Multi-host for iOS Demo

A demo SwiftUI iPhone application intended as an educational tool to demonstrate how you can build a real-time collaborative live streaming experience with [Amazon IVS](https://www.ivs.rocks/).

<img src="app-screenshot.png" alt="A screenshot of the demo application running on an iPhone." />

**This project is intended for education purposes only and not for production usage.**

## Prerequisites

You must have the `ApiUrl` from the [Amazon IVS Multi-host Serverless Demo](https://www.github.com/aws-samples/amazon-ivs-multi-host-serverless-demo).

## Setup

1. Clone the repository to your local machine.
2. Ensure you are using a supported version of Ruby, as [the version included with macOS is deprecated](https://developer.apple.com/documentation/macos-release-notes/macos-catalina-10_15-release-notes#Scripting-Language-Runtimes). This repository is tested with the version in [`.ruby-version`](./.ruby-version), which can be used automatically with [rbenv](https://github.com/rbenv/rbenv#installation).
3. Install the SDK dependency using CocoaPods. This can be done by running the following commands from the repository folder:
   - `bundle install`
   - `bundle exec pod install`
   - For more information about these commands, see [Bundler](https://bundler.io/) and [CocoaPods](https://guides.cocoapods.org/using/getting-started.html).
4. Open `MultiHost-demo.xcworkspace`.
5. Set the `API_URL` constant in the `Constants.swift` file to equal the `ApiUrl` from your deployed [Amazon IVS Multi-host Serverless Demo](https://www.github.com/aws-samples/amazon-ivs-multi-host-serverless-demo).
6. Since iPhone simulators don't currently support the use of cameras or ReplayKit in this app, there are a couple changes you need to make before building and running the app on a physical device.
   1. Have an active Apple Developer account in order to build to physical devices.
   2. Modify the Bundle Identifier for the `MultiHost-demo` target.
   3. Choose a Team for the target.
7. You can now build and run the project on a device.

**IMPORTANT NOTE:** Joining a stage and streaming in the app will create and consume AWS resources, which will cost money.

## Known Issues

- This app has only been tested on devices running iOS 14 or later. While this app may work on devices running older versions of iOS, it has not been tested on them.

## More Documentation

- [Amazon IVS iOS Broadcast SDK Guide](https://docs.aws.amazon.com/ivs/latest/userguide/broadcast-ios.html)
- [More code samples and demos](https://www.ivs.rocks/examples)

## License

This project is licensed under the MIT-0 License. See the LICENSE file.
