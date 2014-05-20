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

NSInteger const kAIMBalloonNumberOfLinks = 10;
CGFloat const kAIMBalloonSpaceBetweenLinks = 1.0f;
CGSize const kAIMBalloonLinkSize = {10, 10};
BOOL const kAIMBalloonDebug = NO;

@interface AIMBalloon (){
    UIDynamicAnimator       *animator;
    UIView                  *balloon;
    UIAttachmentBehavior    *touchAttachmentBehavior;
    
    CAShapeLayer            *shapeLayer;
    NSMutableArray          *linksArray;
    NSMutableArray          *points;
    
    CADisplayLink           *displayLink;
}

@property (nonatomic, weak) UIView *linkedView;

@end

@implementation AIMBalloon

- (instancetype)initWithFrame:(CGRect)frame linkedToView:(UIView*)linkedView{
    if (self = [super initWithFrame:frame]){
        self.linkedView = linkedView;
        
        [self setupAnimator];
        [self setupShapeLayer];
        [self setupLinks];
        [self setupBalloon];
        [self setupBehaviors];
        [self setupDisplayLink];

    }
    return self;
}

#pragma mark - setup

- (void)setupAnimator{
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
}

- (void)setupShapeLayer{
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    shapeLayer.lineJoin = kCALineJoinRound;
    shapeLayer.lineWidth = 1.0f;
    shapeLayer.strokeColor = [UIColor redColor].CGColor;
    shapeLayer.strokeEnd = 1.0f;
    [self.layer addSublayer:shapeLayer];
}

- (void)setupLinks{
    UIView *previousLink = self.linkedView;
    linksArray = [[NSMutableArray alloc] init];
    points = [[NSMutableArray alloc] init];
    [points addObject:[NSValue valueWithCGPoint:previousLink.center]];
    CGFloat currentY = self.linkedView.frame.origin.y + self.linkedView.bounds.size.height;
    
    for (int i = 0; i < kAIMBalloonNumberOfLinks; i++) {
        UIView *link = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2 - kAIMBalloonLinkSize.width/2,
                                                                currentY + kAIMBalloonSpaceBetweenLinks,
                                                                kAIMBalloonLinkSize.width,
                                                                kAIMBalloonLinkSize.height)];
        link.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:kAIMBalloonDebug ? 0.3f : 0.0f];  // debug value
        link.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        [self addSubview:link];
        
        
        UIAttachmentBehavior *attachmentBehavior = nil;
        if (i == 0) {
            attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:link
                                                           offsetFromCenter:UIOffsetMake(0, 0)
                                                           attachedToAnchor:self.linkedView.center];
            
        } else {
            attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:link
                                                           offsetFromCenter:UIOffsetMake(0, -1)
                                                             attachedToItem:previousLink
                                                           offsetFromCenter:UIOffsetMake(0, 1)];
        }
        
        [points addObject:[NSValue valueWithCGPoint:link.center]];
        
        [attachmentBehavior setAction:^{
            points[i+1] = [NSValue valueWithCGPoint:link.center];
        }];
        
        [animator addBehavior:attachmentBehavior];
        
        currentY += kAIMBalloonLinkSize.height + kAIMBalloonSpaceBetweenLinks;
        [linksArray addObject:link];
        previousLink = link;
    }

}

- (void)setupBalloon{
    CGSize ballSize = CGSizeMake(60, 60);
    balloon = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2 - ballSize.width/2,
                                                       kAIMBalloonNumberOfLinks * (kAIMBalloonLinkSize.height + kAIMBalloonSpaceBetweenLinks)
                                                       + CGRectGetMaxY(self.linkedView.frame) + kAIMBalloonSpaceBetweenLinks,
                                                       ballSize.width,
                                                       ballSize.height)];
    balloon.backgroundColor = [UIColor greenColor];
    balloon.layer.cornerRadius = ballSize.width/2;
    [self addSubview:balloon];
    [points addObject:[NSValue valueWithCGPoint:balloon.center]];
}

- (void)setupBehaviors{
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:[linksArray lastObject]
                                                                           attachedToItem:balloon];
    [animator addBehavior:attachmentBehavior];
    
    [attachmentBehavior setAction:^{
        points[kAIMBalloonNumberOfLinks+1] = [NSValue valueWithCGPoint:balloon.center];
    }];
    
    [linksArray addObject:balloon];
    UIGravityBehavior *gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:linksArray];
    [gravityBeahvior setGravityDirection:CGVectorMake(0, -1)];
    [gravityBeahvior setMagnitude:0.5f];
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:linksArray];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior:gravityBeahvior];
    [animator addBehavior:collisionBehavior];
}

- (void)setupDisplayLink{
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayView)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)displayView{
    shapeLayer.path = [[UIBezierPath smoothPathFromArray:points] CGPath];
}


#pragma mark - touches

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
