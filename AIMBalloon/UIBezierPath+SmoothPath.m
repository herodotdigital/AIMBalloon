//
//  UIBezierPath+SmoothPath.m
//  AIMBalloon
//
//  Created by Marek Kotewicz on 11.09.2013.
//  Copyright (c) 2013 AllInMobile. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//based on: http://mobile.tutsplus.com/tutorials/iphone/ios-sdk_freehand-drawing/

#import "UIBezierPath+SmoothPath.h"

@implementation UIBezierPath (SmoothPath)

+ (UIBezierPath*)smoothPathFromArray:(NSArray*)arr{
    if ([arr count] > 0){
        UIBezierPath *bezierPath = [UIBezierPath bezierPath];
        
        NSMutableArray *pts = [arr mutableCopy];
        int i = 0;
        for (; i < pts.count - 4 ; i+= 3){
            CGPoint temp = CGPointMake(([pts[i+2] CGPointValue].x + [pts[i+4] CGPointValue].x)/2.0,
                                       ([pts[i+2] CGPointValue].y + [pts[i+4] CGPointValue].y)/2.0);
            pts[i+3] = [NSValue valueWithCGPoint:temp];
            
            [bezierPath moveToPoint:[pts[i] CGPointValue]];
            [bezierPath addCurveToPoint:temp controlPoint1:[pts[i+1] CGPointValue] controlPoint2:[pts[i+2] CGPointValue]];
        }
        
        switch (pts.count - i) {
            case 4:
                [bezierPath moveToPoint:[pts[i] CGPointValue]];
                [bezierPath addCurveToPoint:[pts[i+3] CGPointValue] controlPoint1:[pts[i+1] CGPointValue] controlPoint2:[pts[i+2] CGPointValue]];
                break;
            case 3:
                [bezierPath moveToPoint:[pts[i] CGPointValue]];
                [bezierPath addCurveToPoint:[pts[i+2] CGPointValue] controlPoint1:[pts[i] CGPointValue] controlPoint2:[pts[i+1] CGPointValue]];
                break;
            case 2:
                [bezierPath moveToPoint:[pts[i] CGPointValue]];
                [bezierPath addLineToPoint:[pts[i+1] CGPointValue]];
                break;
            case 1:
                [bezierPath addLineToPoint:[pts[i] CGPointValue]];
                break;
                
            default:
                break;
        }
        return bezierPath;
    }
    return nil;
}

@end
