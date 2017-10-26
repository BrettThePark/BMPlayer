//
//  BMTimeSlider.swift
//  Pods
//
//  Created by BrikerMan on 2017/4/2.
//
//

import UIKit

@objc
public protocol BMTimeSliderDelegate: NSObjectProtocol {
  
  @objc optional func sliderDidBeginScrubbing(_ slider: BMTimeSlider)
  
  @objc optional func sliderDidEndScrubbing(_ slider: BMTimeSlider)
  
  @objc optional func slider(_ slider: BMTimeSlider, didChangeScrubbingSpeed speed: Float)
  
}

public class BMTimeSlider: UISlider {
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeigt:CGFloat = 2
        let position = CGPoint(x: 0 , y: 14)
        let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeigt))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newx = rect.origin.x - 10
        let newRect = CGRect(x: newx, y: 0, width: 30, height: 30)
        return newRect
    }

    open var scrubbingSpeed: Float = 1.0
    open var scrubbingSpeeds: Array<Float> = [1.0, 0.5, 0.25, 0.1]
    open var scrubbingSpeedChangePositions: Array<Float> = [0.0, 50.0, 75.0, 100.0]
    
    open weak var delegate: BMTimeSliderDelegate!
    
    fileprivate var realPositionValue: Float = 0.0
    fileprivate var beganTrackingLocation = CGPoint.zero
    
    public convenience init() {
      self.init(frame: CGRect.zero)
    }
    
    public override init(frame: CGRect) {
      super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      if aDecoder.containsValue(forKey: "scrubbingSpeeds") {
        scrubbingSpeeds = aDecoder.decodeObject(forKey: "scrubbingSpeeds") as! Array<Float>
      }
      if aDecoder.containsValue(forKey: "scrubbingSpeedChangePositions") {
        scrubbingSpeedChangePositions = aDecoder.decodeObject(forKey: "scrubbingSpeedChangePositions") as! Array<Float>
      }
      if scrubbingSpeeds.count > 0 {
        scrubbingSpeed = scrubbingSpeeds[0]
      }
    }
    
    open override func encode(with aCoder: NSCoder) {
      super.encode(with: aCoder)
      aCoder.encode(scrubbingSpeeds, forKey: "scrubbingSpeeds")
      aCoder.encode(scrubbingSpeedChangePositions, forKey: "scrubbingSpeedChangePositions")
    }
    
    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      let beginTracking = super.beginTracking(touch, with: event)
      if beginTracking {
        // Set the beginning tracking location to the center of the current
        // position of the thumb. This ensures that the thumb is correctly re-positioned
        // when the touch position moves back to the track after tracking in one
        // of the slower tracking zones.
        let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
        beganTrackingLocation = CGPoint(x: thumbRect.origin.x + thumbRect.size.width / 2.0, y: thumbRect.origin.y + thumbRect.size.height / 2.0)
        realPositionValue = value
        
        delegate?.sliderDidBeginScrubbing?(self)
        delegate?.slider?(self, didChangeScrubbingSpeed: scrubbingSpeed)
      }
      return beginTracking
    }
    
    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
      if isTracking {
        let previousLocation = touch.previousLocation(in: self)
        let currentLocation = touch.location(in: self)
        let trackingOffset = currentLocation.x - previousLocation.x
        
        // Find the scrubbing speed that corresponds to the touch's vertical offset.
        let verticalOffset = abs(currentLocation.y - beganTrackingLocation.y)
        var scrubbingSpeedChangePosIndex = indexOfLower(scrubbingSpeed: scrubbingSpeedChangePositions, forOffset: Float(verticalOffset))
        if scrubbingSpeedChangePosIndex == NSNotFound {
          scrubbingSpeedChangePosIndex = scrubbingSpeeds.count
        }
        
        let newScrubbingSpeed = scrubbingSpeeds[scrubbingSpeedChangePosIndex - 1]
        if (newScrubbingSpeed != scrubbingSpeed) {
          delegate?.slider?(self, didChangeScrubbingSpeed: newScrubbingSpeed)
        }
        scrubbingSpeed = newScrubbingSpeed
        
        let trackRect = self.trackRect(forBounds: bounds)
        realPositionValue = realPositionValue + Float(maximumValue - minimumValue) * Float(trackingOffset / trackRect.size.width)
        
        let valueAdjustment = scrubbingSpeed * Float(maximumValue - minimumValue) * Float(trackingOffset / trackRect.size.width)
        var thumbAdjustment: Float = 0.0
        if (((beganTrackingLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) ||
          ((beganTrackingLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y))) {
          // We are getting closer to the slider, go closer to the real location.
          thumbAdjustment = (realPositionValue - value) / Float(1.0 + abs(currentLocation.y - beganTrackingLocation.y))
        }
        value += valueAdjustment + thumbAdjustment
        
        if isContinuous {
          sendActions(for: .valueChanged)
        }
      }
      return isTracking
    }
    
    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
      if isTracking {
        scrubbingSpeed = scrubbingSpeeds[0]
        sendActions(for: .valueChanged)
        delegate?.sliderDidEndScrubbing?(self)
      }
    }
    
    fileprivate func indexOfLower(scrubbingSpeed scrubbingSpeedPositions: Array<Float>, forOffset verticalOffset: Float) -> Int {
      for (i, scrubbingSpeedOffset) in scrubbingSpeedPositions.enumerated() {
        if verticalOffset < scrubbingSpeedOffset {
          return i
        }
      }
      return NSNotFound
    }
    
}
