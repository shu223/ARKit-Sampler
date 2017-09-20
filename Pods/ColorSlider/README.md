# ColorSlider

ColorSlider is a [Swift](https://developer.apple.com/swift/) color picker with a live preview.

Inspired by Snapchat, ColorSlider lets you drag vertically to pick a range of colors and drag to the edges of the superview to select black and white. You can configure and customize `ColorSlider` via a simple API, and receive callbacks via `UIControlEvents`.

![ColorSlider](https://raw.githubusercontent.com/gizmosachin/ColorSlider/master/ColorSlider.gif)

![Pod Version](https://img.shields.io/cocoapods/v/ColorSlider.svg) [![Build Status](https://travis-ci.org/gizmosachin/ColorSlider.svg?branch=master)](https://travis-ci.org/gizmosachin/ColorSlider)

## Version Compatibility

Current Swift compatibility breakdown:

| Swift Version | Framework Version |
| ------------- | ----------------- |
| 3.0	        | master          	|
| 2.3	        | 2.5.1        		|

## Usage

Create and add an instance of  ColorSlider to your view hierarchy.

``` Swift
let colorSlider = ColorSlider()
colorSlider.frame = CGRectMake(0, 0, 12, 150)
view.addSubview(colorSlider)
```

ColorSlider is a subclass of `UIControl` and supports the following `UIControlEvents`:

- `.touchDown`
- `.valueChanged`
- `.touchUpInside`
- `.touchUpOutside`
- `.touchCancel`

You can get the currently selected color with the `color` property.

``` Swift
colorSlider.addTarget(self, action: #selector(ViewController.changedColor(_:)), forControlEvents: .valueChanged)

func changedColor(_ slider: ColorSlider) {
    var color = slider.color
    // ...
}
```

Enable live color preview:

``` swift
colorSlider.previewEnabled = true
```

Use a horizontal slider:

```swift
colorSlider.orientation = .horizontal
```

Customize appearance attributes:

``` Swift
colorSlider.borderWidth = 2.0
colorSlider.borderColor = UIColor.white
```

[Please see the documentation](http://gizmosachin.github.io/ColorSlider/docs) and check out the sample app (Sketchpad) for more details.

## Installation

### CocoaPods

ColorSlider is available for installation using [CocoaPods](http://cocoapods.org/). To integrate, add the following to your Podfile`:

``` ruby
platform :ios, '9.0'
use_frameworks!

pod 'ColorSlider', '~> 3.0.1'
```

### Carthage

ColorSlider  is also available for installation using [Carthage](https://github.com/Carthage/Carthage). To integrate, add the following to your `Cartfile`:

``` odgl
github "gizmosachin/ColorSlider" >= 3.0.1
```

### Swift Package Manager

ColorSlider is also available for installation using the [Swift Package Manager](https://swift.org/package-manager/). Add the following to your `Package.swift`:

``` swift
import PackageDescription

let package = Package(
    name: "MyProject",
    dependencies: [
        .Package(url: "https://github.com/gizmosachin/ColorSlider.git", majorVersion: 0),
    ]
)
```

### Manual

You can also simply copy  `ColorSlider.swift`  into your Xcode project.

## Example Project

ColorSlider comes with an example project called Sketchpad, a simple drawing app. To try it, install [CocoaPods](http://cocoapods.org/) and run `pod install` under the `Example` directory. Then, open `Sketchpad.xcworkspace`.

## How it Works

ColorSlider uses [HSB](https://en.wikipedia.org/wiki/HSB) and defaults to a saturation and brightness: 100%. 

When the `orientation` is set to `.vertical`, dragging vertically adjusts the hue, and dragging outside adjusts the saturation and brightness as follows:

- Inside the frame, dragging vertically adjusts the hue
- Outside the frame, dragging horizontally adjusts the saturation
- Outside the frame, dragging vertically adjusts the brightness

Adjusting the brightness lets you select black and white by first dragging on the slider, then moving your finger outside the frame to the top left (to select white) or bottom left (to select black) of the superview.

## License

ColorSlider is available under the MIT license, see the [LICENSE](https://github.com/gizmosachin/ColorSlider/blob/master/LICENSE) file for more information.
