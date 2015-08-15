/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, James Cox.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKXAxisView.h"
#import "ORKGraphView_Internal.h"


static const CGFloat LastLabelBackgroundPadding = 10.0;

@implementation ORKXAxisView {
    NSMutableArray *_titleLabels;
    __weak ORKGraphView *_parentGraphView;
    CALayer *_lineLayer;
    NSMutableArray *_titleTickLayers;
}

- (instancetype)initWithParentGraphView:(ORKGraphView *)parentGraphView {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _titleLabels = [NSMutableArray new];
        _parentGraphView = parentGraphView;
        
        _lineLayer = [CALayer layer];
        _lineLayer.backgroundColor = _parentGraphView.axisColor.CGColor;
        [self.layer addSublayer:_lineLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat viewWidth = self.bounds.size.width;
    _lineLayer.frame = CGRectMake(0, -0.5, viewWidth, 1);
    NSUInteger index = 0;
    NSUInteger numberOfTitleLabels = _titleTickLayers.count;
    for (CALayer *titleTickLayer in _titleTickLayers) {
        CGFloat positionOnXAxis = xAxisPoint(index, numberOfTitleLabels, viewWidth);
        titleTickLayer.frame = CGRectMake(positionOnXAxis - 0.5, -ORKGraphViewAxisTickLength, 1, ORKGraphViewAxisTickLength);
        index++;
    }
    ((UILabel *)_titleLabels.lastObject).layer.cornerRadius = (self.bounds.size.height - LastLabelBackgroundPadding) * 0.5;
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray new];
    
    NSUInteger numberOfTitleLabels = _titleLabels.count;
    for (NSUInteger i = 0; i < numberOfTitleLabels; i++) {
        UILabel *label = _titleLabels[i];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:label
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:label.superview
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0
                                                             constant:0.0]];
        
        if (i == 0) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:label
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:label.superview
                                                                attribute:NSLayoutAttributeLeading
                                                               multiplier:1.0
                                                                 constant:0.0]];
        } else {
            // This "magic" multiplier constraints evenly space the labels among
            // the superview without having to manually specify its width.
            CGFloat multiplier = 1.0 - ((CGFloat)(numberOfTitleLabels-i-1) / (numberOfTitleLabels-1));
            [constraints addObject:[NSLayoutConstraint constraintWithItem:label
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:label.superview
                                                                attribute:NSLayoutAttributeTrailing
                                                               multiplier:multiplier
                                                                 constant:0.0]];
        }
        
        if (i == _titleLabels.count - 1) {
            NSLayoutConstraint *constraint = nil;
            
            constraint = [NSLayoutConstraint constraintWithItem:label
                                                      attribute:NSLayoutAttributeHeight
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:label.superview
                                                      attribute:NSLayoutAttributeHeight
                                                     multiplier:1.0
                                                       constant:-LastLabelBackgroundPadding];
            constraint.priority = UILayoutPriorityRequired - 1;
            [constraints addObject:constraint];
            
            constraint = [NSLayoutConstraint constraintWithItem:label
                                                      attribute:NSLayoutAttributeWidth
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:label.superview
                                                      attribute:NSLayoutAttributeHeight
                                                     multiplier:1.0
                                                       constant:-LastLabelBackgroundPadding];
            constraint.priority = UILayoutPriorityRequired - 1;
            [constraints addObject:constraint];
        }
    }
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateTitles {
    [_titleLabels makeObjectsPerformSelector:@selector(removeFromSuperview)]; // Old constraints automatically removed when removing the views
    [_titleLabels removeAllObjects];
    [_titleTickLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_titleTickLayers removeAllObjects];
    
    if ([_parentGraphView.dataSource respondsToSelector:@selector(graphView:titleForXAxisAtIndex:)]) {
        NSUInteger numberOfTitleLabels = [_parentGraphView numberOfXAxisPoints];
        for (NSUInteger i = 0; i < numberOfTitleLabels; i++) {
            NSString *title = [_parentGraphView.dataSource graphView:_parentGraphView titleForXAxisAtIndex:i];
            UILabel *label = [UILabel new];
            label.text = title;
            label.font = [UIFont systemFontOfSize:12.0];
            label.numberOfLines = 2;
            label.textAlignment = NSTextAlignmentCenter;
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = 0.7;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            if (i < (numberOfTitleLabels - 1)) {
                label.textColor = self.tintColor;
            } else {
                label.textColor = [UIColor whiteColor];
                label.backgroundColor = self.tintColor;
                label.layer.cornerRadius = (self.bounds.size.height - LastLabelBackgroundPadding) * 0.5;
                label.layer.masksToBounds = YES;
            }
            
            [self addSubview:label];
            [_titleLabels addObject:label];
            
            // Add vertical tick layers above labels
            for (NSUInteger i = 0; i < numberOfTitleLabels; i++) {
                CALayer *titleTickLayer = [CALayer layer];
                CGFloat positionOnXAxis = xAxisPoint(i, numberOfTitleLabels, self.bounds.size.width);
                titleTickLayer.frame = CGRectMake(positionOnXAxis - 0.5, -ORKGraphViewAxisTickLength, 1, ORKGraphViewAxisTickLength);
                titleTickLayer.backgroundColor = _parentGraphView.axisColor.CGColor;
                [self.layer addSublayer:titleTickLayer];
                [_titleTickLayers addObject:titleTickLayer];
            }

        }
        [self setUpConstraints];
    }
}

- (void)tintColorDidChange {
    NSUInteger numberOfTitleLabels = _titleLabels.count;
    for (NSUInteger i = 0; i < numberOfTitleLabels; i++) {
        UILabel *label = _titleLabels[i];
        if (i < (numberOfTitleLabels - 1)) {
            label.textColor = self.tintColor;
        } else {
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = self.tintColor;
        }
    }
}

@end
