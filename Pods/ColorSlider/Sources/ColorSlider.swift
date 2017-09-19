//
//  ColorSlider.swift
//
//  Created by Sachin Patel on 1/11/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015-Present Sachin Patel (http://gizmosachin.com/)
//    
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//    
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//    
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import Foundation
import CoreGraphics

/// The main ColorSlider class.
@IBDesignable final public class ColorSlider: UIControl {
	/// The current color of the `ColorSlider`.
	public var color: UIColor {
		return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
	}
	
	// MARK: Customization
	/// The display orientation of the `ColorSlider`.
	public enum Orientation {
		/// Displays `ColorSlider` vertically.
		case vertical
		
		/// Displays `ColorSlider` horizontally.
		case horizontal
	}
	
	/// The orientation of the `ColorSlider`. Defaults to `.Vertical`.
	public var orientation: Orientation = .vertical {
		didSet {
			switch orientation {
			case .vertical:
				drawLayer.startPoint = CGPoint(x: 0.5, y: 1)
				drawLayer.endPoint = CGPoint(x: 0.5, y: 0)
			case .horizontal:
				drawLayer.startPoint = CGPoint(x: 0, y: 0.5)
				drawLayer.endPoint = CGPoint(x: 1, y: 0.5)
			}
		}
	}
	
	/// A boolean value that determines whether or not a color preview is shown while dragging.
	@IBInspectable public var previewEnabled: Bool = false
	
	/// The width of the ColorSlider's border.
	@IBInspectable public var borderWidth: CGFloat = 1.0 {
		didSet {
			drawLayer.borderWidth = borderWidth
		}
	}
	
	/// The color of the ColorSlider's border.
	@IBInspectable public var borderColor: UIColor = UIColor.black {
		didSet {
			drawLayer.borderColor = borderColor.cgColor
		}
	}
	
	/// The corner radius of the ColorSlider.
	/// seealso: setsCornerRadiusAutomatically
	@IBInspectable public var cornerRadius: CGFloat = 0.0 {
		didSet {
			updateCornerRadius()
		}
	}

	/// Whether the slider should automatically adjust its corner radius.
	/// When this value is `true`, `cornerRadius` is ignored.
	/// When this value is `false`, the `cornerRadius` is used.
    @IBInspectable public var setsCornerRadiusAutomatically: Bool = true {
        didSet {
        	updateCornerRadius()
        }
    }
    
    // MARK: Internal
	/// Internal `CAGradientLayer` used for drawing the `ColorSlider`.
	private lazy var drawLayer: CAGradientLayer = {
		let drawLayer = CAGradientLayer()
		self.layer.insertSublayer(drawLayer, at: 0)
		return drawLayer
	}()

	/// The hue of the current color.
    private var hue: CGFloat = 0
	
	/// The saturation of the current color.
	private var saturation: CGFloat = 1
	
	/// The brightness of the current color.
    private var brightness: CGFloat = 1
	
	// MARK: Preview view
	/// The color preview view. Only shown if `previewEnabled` is set to `true`.
	private var previewView: UIView = UIView()
	
	/// The edge length of the preview view.
	private let previewDimension: CGFloat = 30
	
	/// The amount that the `previewView` is drawn away from the `ColorSlider` bar.
	private let previewOffset: CGFloat = 44
	
	/// The duration of the preview show or hide animation.
	private let previewAnimationDuration: TimeInterval = 0.10
	
    // MARK: - Initializers
	/// Creates a `ColorSlider` with a frame of `CGRect.zero`.
	public init() {
		super.init(frame: CGRect.zero)
		commonInit()
    }
	
	/// Creates a `ColorSlider` with a frame of `frame`.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
	}
	
	/// Creates a `ColorSlider` from Interface Builder.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
		commonInit()
    }
	
	/// Sets up internal views.
	public func commonInit() {
		backgroundColor = UIColor.clear
		
		drawLayer.frame = layer.bounds
		drawLayer.masksToBounds = true
		drawLayer.borderColor = borderColor.cgColor
		drawLayer.borderWidth = borderWidth
		drawLayer.startPoint = CGPoint(x: 0.5, y: 1)
		drawLayer.endPoint = CGPoint(x: 0.5, y: 0)
		updateCornerRadius()
		
		// Draw gradient
		let hues: [CGFloat] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
		drawLayer.locations = hues.map({ (hue) -> NSNumber in
			return NSNumber(floatLiteral: Double(hue))
		})
		drawLayer.colors = hues.map({ (hue) -> CGColor in
			return UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor
		})
		
		previewView.clipsToBounds = true
		previewView.layer.cornerRadius = previewDimension / 2
		previewView.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
		previewView.layer.borderWidth = 1.0
	}
	
    // MARK: - UIControl
	/// Begins tracking a touch when the user drags on the `ColorSlider`.
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
		
		// Reset saturation and brightness
		saturation = 1.0
		brightness = 1.0
		
        updateForTouch(touch, touchInside: true)
		
        showPreview(touch)
        
        sendActions(for: .touchDown)
        return true
    }
	
	/// Continues tracking a touch as the user drags on the `ColorSlider`.
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        updateForTouch(touch, touchInside: isTouchInside)
		
        updatePreview(touch)
        
        sendActions(for: .valueChanged)
        return true
    }
	
	/// Ends tracking a touch when the user finishes dragging on the `ColorSlider`.
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
		
		guard let endTouch = touch else { return }
        updateForTouch(endTouch, touchInside: isTouchInside)
		
        removePreview()
		
		sendActions(for: isTouchInside ? .touchUpInside : .touchUpOutside)
    }
	
	/// Cancels tracking a touch when the user cancels dragging on the `ColorSlider`.
    public override func cancelTracking(with event: UIEvent?) {
        sendActions(for: .touchCancel)
    }
	
	// MARK: -
	///	Updates the `ColorSlider` color.
	///
	///	- parameter touch: The touch that triggered the update.
	///	- parameter touchInside: A boolean value that is `true` if `touch` was inside the frame of the `ColorSlider`.
    private func updateForTouch(_ touch: UITouch, touchInside: Bool) {
        if touchInside {
            // Modify hue at constant brightness
            let locationInView = touch.location(in: self)
			
			// Calculate based on orientation
			if orientation == .vertical {
				hue = 1 - max(0, min(1, (locationInView.y / frame.height)))
			} else {
				hue = max(0, min(1, (locationInView.x / frame.width)))
			}
            brightness = 1
			
        } else {
            // Modify saturation and brightness for the current hue
			guard let _superview = superview else { return }
			let locationInSuperview = touch.location(in: _superview)
			let horizontalPercent = max(0, min(1, (locationInSuperview.x / _superview.frame.width)))
			let verticalPercent = max(0, min(1, (locationInSuperview.y / _superview.frame.height)))
			
			// Calculate based on orientation
			if orientation == .vertical {
				saturation = horizontalPercent
				brightness = 1 - verticalPercent
			} else {
				saturation = verticalPercent
				brightness = 1 - horizontalPercent
			}
        }
    }
	
	/// Draws necessary parts of the `ColorSlider`.
	private func layout(_ sublayer: CALayer, parent layer: CALayer) {
		guard sublayer != previewView.layer else { return }
		updateCornerRadius()
		sublayer.frame = layer.bounds
	}
	
	public override func layoutSublayers(of layer: CALayer) {
		super.layoutSublayers(of: layer)
		layer.sublayers?.forEach { layout($0, parent: layer) }
	}

	func updateCornerRadius() {
		if setsCornerRadiusAutomatically {
        	let shortestSide = (bounds.width > bounds.height) ? bounds.height : bounds.width
        	drawLayer.cornerRadius = shortestSide / 2.0
        } else {
        	drawLayer.cornerRadius = cornerRadius
        }
	}
    
    // MARK: - Preview
	///	Shows the color preview.
	///
	///	- parameter touch: The touch that triggered the update.
    private func showPreview(_ touch: UITouch) {
		if !previewEnabled { return }
		
        // Initialize preview in proper position, save frame
        updatePreview(touch)
		previewView.transform = minimizedTransform(for: previewView.frame)
        
        addSubview(previewView)
        UIView.animate(withDuration: previewAnimationDuration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { () -> Void in
            self.previewView.transform = CGAffineTransform.identity
		}, completion: nil)
    }
	
	///	Updates the color preview.
	///
	///	- parameter touch: The touch that triggered the update.
    private func updatePreview(_ touch: UITouch) {
		if !previewEnabled { return }
		
		// Calculate the position of the preview
		let location = touch.location(in: self)
		var x = orientation == .vertical ? -previewOffset : location.x
		var y = orientation == .vertical ? location.y : -previewOffset
		
		// Restrict preview frame to slider bounds
		if orientation == .vertical {
			y = max(0, location.y - (previewDimension / 2))
			y = min(bounds.height - previewDimension, y)
		} else {
			x = max(0, location.x - (previewDimension / 2))
			x = min(bounds.width - previewDimension, x)
		}
		
		// Update the preview
		let previewFrame = CGRect(x: x, y: y, width: previewDimension, height: previewDimension)
		previewView.frame = previewFrame
		previewView.backgroundColor = color
    }
	
	/// Removes the color preview
    private func removePreview() {
		if !previewEnabled || previewView.superview == nil { return }
		
		UIView.animate(withDuration: previewAnimationDuration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: { () -> Void in
			self.previewView.transform = self.minimizedTransform(for: self.previewView.frame)
		}, completion: { (completed: Bool) -> Void in
			self.previewView.removeFromSuperview()
			self.previewView.transform = CGAffineTransform.identity
		})
    }
	
	///	Calculates the transform from `rect` to the minimized preview view.
	///
	///	- parameter rect: The actual frame of the preview view.
	///	- returns: The transform from `rect` to generate the minimized preview view.
    private func minimizedTransform(for rect: CGRect) -> CGAffineTransform {
        let minimizedDimension: CGFloat = 5.0
		
		let scale = minimizedDimension / previewDimension
		let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
		
		let tx = orientation == .vertical ? previewOffset : 0
		let ty = orientation == .vertical ? 0 : previewOffset
		let translationTransform = CGAffineTransform(translationX: tx, y: ty)
		
		return scaleTransform.concatenating(translationTransform)
    }
}
