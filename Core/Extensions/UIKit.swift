//
//  UIKitExtensions.swift
//  MKNetworkKit
//
//  Created by Mugunth Kumar
//  Copyright © 2015 - 2020 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//
//  MIT LICENSE (REQUIRES ATTRIBUTION)
//	ATTRIBUTION FREE LICENSING AVAILBLE (for a license fee)
//  Email mugunth.kumar@gmail.com for details
//
//  Created by Mugunth Kumar (@mugunthkumar)
//  Copyright (C) 2015-2025 by Steinlogic Consulting And Training Pte Ltd.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit
import ImageIO
#if os(watchOS)
  import WatchKit
#endif

// MARK: Extension methods on String to load a remote image
public extension String {

  public var filePathSafeString: String {    
    let characterSet = NSCharacterSet(charactersInString: "/*?!").invertedSet
    return stringByAddingPercentEncodingWithAllowedCharacters(characterSet) ?? ""
  }

  static var imageHost: Host?
  public func loadRemoteImage(decompress: Bool = true, scale: CGFloat? = nil, handler:(UIImage?, Bool) -> Void) -> Request? {
    var token: dispatch_once_t = 0
    dispatch_once(&token) {
      if String.imageHost == nil {
        String.imageHost = Host(cacheDirectory: "MKNetworkKit")
      }
    }
    return String.imageHost?.request(withAbsoluteURLString:self)?
      .completion { (request) -> Void in
        let cachedResponse = [.ResponseAvailableFromCache, .StaleResponseAvailableFromCache].contains(request.state)
        if decompress {
          handler(request.responseAsDecompressedImage(scale), cachedResponse)
        } else {
          handler(request.responseAsImage(scale), cachedResponse)
        }
      }.run()
  }
}

extension Request {
  public func responseAsImage(scale: CGFloat? = nil) -> UIImage? {
    var token: dispatch_once_t = 0
    var mutableScale = scale
    if mutableScale == nil { // use device scale
      mutableScale = 2
      dispatch_once(&token) {
        #if os(watchOS)
          mutableScale = WKInterfaceDevice.currentDevice().screenScale
        #endif
        #if os(iOS)
          mutableScale = UIScreen.mainScreen().scale
        #endif
      }
    }
    return UIImage(data:responseData, scale: mutableScale!)
  }
  
  public func responseAsDecompressedImage (scale: CGFloat? = nil) -> UIImage? {
    guard let source = CGImageSourceCreateWithData(responseData as CFDataRef, nil) else { return nil }
    guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0,
                                                        [(kCGImageSourceShouldCache as String): false]) else { return nil }
    
    var token: dispatch_once_t = 0
    var mutableScale = scale
    if mutableScale == nil { // use device scale
      mutableScale = 2
      dispatch_once(&token) {
        #if os(watchOS)
          mutableScale = WKInterfaceDevice.currentDevice().screenScale
        #endif
        #if os(iOS)
          mutableScale = UIScreen.mainScreen().scale
        #endif
      }
    }
    return UIImage(CGImage: cgImage, scale: mutableScale!, orientation: .Up)
  }
  
  #if APPEX
  #else
  public static var automaticNetworkActivityIndicator: Bool = false {
    didSet {
      if automaticNetworkActivityIndicator {
        Request.runningRequestsUpdatedHandler = { count in
          dispatch_async(dispatch_get_main_queue()) {
            #if os(iOS)
              UIApplication.sharedApplication().networkActivityIndicatorVisible = count > 0
            #endif
          }
        }
      }
    }
  }
  #endif
}
