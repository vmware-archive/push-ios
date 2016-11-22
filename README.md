iOS Push Client SDK
===================

The Push SDK requires iOS 8.0 or greater.

The Push iOS SDK v1.7.0 is compatible with the Push Notification Service 1.7.0.

Push SDK Usage
--------------

For more information please visit the [docs site](http://docs.pivotal.io/mobile/push/ios/)


Building the SDK
----------------

The source code of the project is divided into two separate projects:

 * PCFPush - The redistributable portion of the framework.

 * PCFPushSpecs - This target produces an application that links against the PCFPush source code directly and runs the unit tests.

	* Unit tests implemented using [Kiwi](https://github.com/kiwi-bdd/Kiwi).
	* Dependency management with [CocoaPods](http://cocoapods.org/).  Note that we require **Cocoapods version 0.39.0**.
	* Run `pod install` from the project's base directory to set up the test project for tests.  Make sure to open the generated workspace file.

Building the Framework
----------------------

The "PCFPush" target produces a universal framework suitable for building against ARM and Simulator platforms.

To build the framework load the PCFPush project in Xcode.  Select the "PCFPush" target and select "Archive" from the "Build" menu in Xcode.  After the project is built, Xcode should open a Finder window containing the resultant framework.

Alternatively, run 'build-package.sh' in the 'scripts' directory.
