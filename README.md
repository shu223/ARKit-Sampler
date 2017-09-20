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

![](README_resources/firstar.png)


### Plane Detection

A sample to show how simply ARKit can detect planes.

![](README_resources/plane.png)


### Virtual Object

A sample to show how to add a virtual object to a detected plane.

![](README_resources/virtual.png)


### AR Interaction

Interactions with virtual objects or detected plane anchors.


### AR Measure

Measuring lengths in the real space.

![](README_resources/measure.png)


### AR Drawing

Drawing in the real space.

![](README_resources/ardrawing.png)


### Core ML + ARKit",

AR Tagging to detected objects using Core ML.

![](README_resources/coreml.png)

