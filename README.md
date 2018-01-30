# ARKit-Sampler

[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
)](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat
)](https://developer.apple.com/swift)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat
)](http://mit-license.org)
[![Twitter](https://img.shields.io/badge/twitter-@shu223-blue.svg?style=flat)](http://twitter.com/shu223)

ARKit-Sampler is a collection of ARKit samples.


## How to build

1. Download `Inceptionv3.mlmodel` from [here](https://developer.apple.com/machine-learning/
), then put it into the `mlmodels` folder.
2. Open `ARKit-Sampler.xcworkspace` with Xcode 9 and build it.

It can **NOT** run on **Simulator**. (Because it uses Metal.)


## Contents


### 3 lines AR

A simple AR with 3 lines code.

<img src="README_resources/firstar.png" width="200">


### Plane Detection

A sample to show how simply ARKit can detect planes.

<img src="README_resources/plane.png" width="200">


### Virtual Object

A sample to show how to add a virtual object to a detected plane.

<img src="README_resources/virtual.png" width="200">


### AR Interaction

Interactions with virtual objects or detected plane anchors.

![](README_resources/interaction2.gif)

### AR Measure

Measuring lengths in the real space.

<img src="README_resources/measure.png" width="200">


### AR Drawing

Drawing in the real space.

<img src="README_resources/ardrawing.png" width="200">


### Core ML + ARKit",

AR Tagging to detected objects using Core ML.

<img src="README_resources/coreml.png" width="200">


### Metal + ARKit

Rendering with Metal.

![](README_resources/arkitmetal.gif)


### Metal + ARKit (SCNProgram)

Rendering the virtual node's material with Metal shader using `SCNProgram`.

<img src="README_resources/arscnprogram.png" width="200">

### Simple Face Tracking

Simplest Face-Based AR implementation.


### Coming soon...

- Audio + ARKit
- Core Location / MapKit + ARKit
- etc...


## Author

**Shuichi Tsutsumi**

iOS programmer from Japan.

- PAST WORKS:  [My Profile Summary](https://medium.com/@shu223/my-profile-summary-f14bfc1e7099#.vdh0i7clr)
- PROFILES: [LinkedIn](https://www.linkedin.com/in/shuichi-tsutsumi-525b755b/)
- BLOGS: [English](https://medium.com/@shu223/) / [Japanese](http://d.hatena.ne.jp/shu223/)
- CONTACTS: [Twitter](https://twitter.com/shu223) / [Facebook](https://www.facebook.com/shuichi.tsutsumi)


## Special Thanks

The icon is designed by [Okazu](https://www.facebook.com/pashimo)
