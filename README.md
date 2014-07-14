Push Notifications
=============================================
[see the public docs](https://github.com/cfmobile/docs-pushnotifications-ios/blob/master/README.md)

Building the SDK itself
-----------------------

Although you do not need any extra libraries or frameworks to build the project itself, you will need to modify
your local Xcode installation in order to support building universal frameworks.  You will need to use this project
in order to build this project:

 * https://github.com/kstenerud/iOS-Universal-Framework

Clone that repository onto your computer, close XCode, and run the `install.sh` script in the `Real
Framework` subdirectory.

The source code of the project is divided into three projects:

 * MSSPushSDK - framework target
     The redistributable portion of the framework.

 * MSSPushSpecs - iOS testing target
     Unit tests.  Implemented using [Kiwi](https://github.com/kiwi-bdd/Kiwi).
     Uses [cocoapods](http://cocoapods.org/) to manage dependencies.

	 This target produces an application that links against the MSSPushSDK source code directly
	 and runs the unit tests.

Building the Framework
----------------------

The "MSSPushSDK" target produces a universal framework suitable for building against arm and simulator platforms.  This target
depends on the [iOS Universal Framework](https://github.com/kstenerud/iOS-Universal-Framework) build system to produce this framework.

To build the framework, make sure the iOS Universal Framework is installed and load the MSSPushSDK project in Xcode.  Select
the "MSSPushSDK" target and select "Archive" from the "Build" menu in Xcode.  After the project is built, Xcode should open a
Finder window containing the resultant framework.

