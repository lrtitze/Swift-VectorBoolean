Swift VectorBoolean for iOS
===========================

This is an iOS 8 and higher Swift 2 rewrite of the code for Andy Finnell's article [How to implement boolean operations on bezier paths](http://losingfight.com/blog/2011/07/07/how-to-implement-boolean-operations-on-bezier-paths-part-1/). It is a literal translation of his original Objective-C Mac OS X [VectorBoolean](https://bitbucket.org/andyfinnell/vectorboolean) library with a tiny bit of Swifty goodness introduced.

It compiles under XCode 7 and includes an iOS app which tests the bezier operations and serves as an example of using the code.

I wrote this because I had a specific need for boolean operations on bezier paths in iOS. Rather than simply modifing the original Objective-C code to work on iOS, I bit the bullet and decided to redo it in Swift. Six months after beginning, I'm pleased to share it with you. I hope you enjoy it.

<img src="images/SVB-icon.png" width="128" height="128">

**Note:** *This code is now compatible with both 32-bit and 64-bit iOS devices.* Due to numeric precision limitations of the 32 bit version of iOS however, this code will misbehave on fractionally dimensioned bezier curves for the 32-bit case. For example, a line from 0.01, 0.01 to 0.02, 0.02 will be behave as a single point on an iPhone 4s but not on an iPhone 5s.

For the majority of applications this should not be a significant limitation.

## iOS Screens

<img src="images/SVB-shapes.png" width="320" height="568" hspace="10"><img src="images/SVB-original.png" width="320" height="568" hspace="10"><img src="images/SVB-union.png" width="320" height="568" hspace="10"><img src="images/SVB-intersect.png" width="320" height="568" hspace="10"><img src="images/SVB-subtract.png" width="320" height="568" hspace="10"><img src="images/SVB-join.png" width="320" height="568" hspace="10"><img src="images/SVB-options.png" width="320" height="568" hspace="10"><img src="images/SVB-detailed.png" width="320" height="568" hspace="10">
