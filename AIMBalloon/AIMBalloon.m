//
//  AIMBalloon.m
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

//based on: https://gist.github.com/Dimillian/5868026/raw/1023ff9466e09f73af4944273f3a2cbc4e65bf2a/gistfile1.txt

#import "AIMBalloon.h"
#import "UIBezierPath+SmoothPath.h"

#if !__has_feature(objc_arc)
#error AIMBalloon must be built with ARC.
// You can turn on ARC for only AIMBalloon files by adding -fobjc-arc to the build phase for each of its files.
#endif

#ifndef __IPHONE_7_0
#error "AIMBalloon uses features only available in iOS SDK 7.0 and later."
#endif

@interface AIMBalloon (){
    UIDynamicAnimator       *animator;
    UIView                  *balloon;
    UIAttachmentBehavior    *touchAttachmentBehavior;
}

@end

@implementation AIMBalloon

- (instancetype)initWithFrame:(CGRect)frame linkedToView:(UIView*)linkedView{
    if (self = [super initWithFrame:frame]){
        
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
        UIView *previousLink        = linkedView;
        
        // setup variables
        NSInteger numberOfLinks     = 10;
        CGFloat spaceBetweenLinks   = 2.0f;
        CGSize linkSize             = CGSizeMake(10, 10);
        
        // setup line parameters
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.fillColor = [[UIColor clearColor] CGColor];
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.lineWidth = 1.0f;
        shapeLayer.strokeColor = [UIColor redColor].CGColor;
        shapeLayer.strokeEnd = 1.0f;
        
        [self.layer addSublayer:shapeLayer];
        
        NSMutableArray *linksArray      = [[NSMutableArray alloc] initWithCapacity:numberOfLinks];
        NSMutableArray *points          = [[NSMutableArray alloc] initWithCapacity:numberOfLinks + 2];
        
        [points addObject:[NSValue valueWithCGPoint:previousLink.center]];
        
        CGFloat currentY = linkedView.frame.origin.y + linkedView.bounds.size.height;

        // create links
        for (int i = 0; i < numberOfLinks; i++) {
            UIView *link = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2 - linkSize.width/2, currentY + spaceBetweenLinks, linkSize.width, linkSize.height)];
            link.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.0];  // debug value
            link.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
            
            [self addSubview:link];
            
            
            UIAttachmentBehavior *attachmentBehavior = nil;
            if (i == 0) {
                attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:link
                                                               offsetFromCenter:UIOffsetMake(0, 0)
                                                               attachedToAnchor:linkedView.center];
                
            } else {
                attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:link
                                                               offsetFromCenter:UIOffsetMake(0, -1)
                                                                 attachedToItem:previousLink
                                                               offsetFromCenter:UIOffsetMake(0, 1)];
            }
            
            [points addObject:[NSValue valueWithCGPoint:link.center]];
            
            [attachmentBehavior setAction:^{
                points[i+1] = [NSValue valueWithCGPoint:link.center];
                shapeLayer.path = [[UIBezierPath smoothPathFromArray:points] CGPath];
            }];
            
            [animator addBehavior:attachmentBehavior];
            
            currentY += linkSize.height + spaceBetweenLinks;
            [linksArray addObject:link];
            previousLink = link;
        }
        
        // create ballon
        CGSize ballSize = CGSizeMake(60, 60);
        balloon = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2 - ballSize.width/2, currentY + spaceBetweenLinks, ballSize.width, ballSize.height)];
        balloon.backgroundColor = [UIColor greenColor];
        balloon.layer.cornerRadius = ballSize.width/2;
        [self addSubview:balloon];

        

        // Connect balloon to the chain
        UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:previousLink
                                                                               attachedToItem:balloon];
        [animator addBehavior:attachmentBehavior];
        
        [points addObject:[NSValue valueWithCGPoint:balloon.center]];
        [attachmentBehavior setAction:^{
            points[numberOfLinks+1] = [NSValue valueWithCGPoint:balloon.center];
            shapeLayer.path = [[UIBezierPath smoothPathFromArray:points] CGPath];
        }];
        
        // Apply gravity and collision
        [linksArray addObject:balloon];
        UIGravityBehavior *gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:linksArray];
        [gravityBeahvior setGravityDirection:CGVectorMake(0, -1)];
        [gravityBeahvior setMagnitude:0.5f];
        UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:linksArray];
        collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
        [animator addBehavior:gravityBeahvior];
        [animator addBehavior:collisionBehavior];
        
    }
    return self;
}

// Let the user pull the balloon around
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    touchAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:balloon
                                                        attachedToAnchor:balloon.center];
    [animator addBehavior:touchAttachmentBehavior];
    [touchAttachmentBehavior setFrequency:1.0];
    [touchAttachmentBehavior setDamping:0.1];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    touchAttachmentBehavior.anchorPoint = [touch locationInView:self];;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [animator removeBehavior:touchAttachmentBehavior];
    touchAttachmentBehavior = nil;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [animator removeBehavior:touchAttachmentBehavior];
    touchAttachmentBehavior = nil;
}



@end
