//
//  NYTScalingImageView.m
//  Pods
//
//  Created by Harrison, Andrew on 7/23/13.
//  Copyright (c) 2015 The New York Times Company. All rights reserved.
//

#import <objc/objc.h>
#import "NYTScalingImageView.h"

#import "tgmath.h"
#import "UIImageView+WebCache.h"
#import "NYTPhotoViewController.h"

@interface NYTScalingImageView ()

@property(nonatomic) UIImageView *imageView;

@end

@implementation NYTScalingImageView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithImage:nil frame:frame];
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
    [self centerScrollViewContents];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self centerScrollViewContents];
    [self updateZoomScale];
}

#pragma mark - NYTScalingImageView

- (id)initWithImage:(UIImage *)image frame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setupInternalImageViewWithImage:image];
        [self setupImageScrollView];
        [self updateZoomScale];
    }

    return self;
}

- (instancetype)initWithURL:(NSURL *)url frame:(CGRect)frame placeholderImage:(UIImage *)placeholderImage completedBlock:(NYTScallingImageViewLoadingCompletedBlock)completedBlock {
    self = [super initWithFrame:frame];

    if (self) {
        self.imageView = [[UIImageView alloc] initWithImage:placeholderImage];
        [self updateImage:placeholderImage];
        [self addSubview:self.imageView];

        __weak __typeof(self) weakSelf = self;
        [self.imageView sd_setImageWithURL:url
                          placeholderImage:placeholderImage
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     __strong __typeof(weakSelf) strongSelf = weakSelf;
                                     if (!error) {
                                         [strongSelf updateImage:image];
                                     }
                                     if (completedBlock) {
                                         completedBlock(image, error);
                                     }
                                 }];
        [self setupImageScrollView];
        [self updateZoomScale];
    }

    return self;
}


#pragma mark - Setup

- (void)setupInternalImageViewWithImage:(UIImage *)image {
    self.imageView = [[UIImageView alloc] initWithImage:image];
    [self updateImage:image];

    [self addSubview:self.imageView];
}

- (void)setupInternalImageViewImageURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage {

    self.imageView = [[UIImageView alloc] initWithImage:placeholderImage];
    [self updateImage:placeholderImage];
    [self addSubview:self.imageView];

    __weak __typeof(self) weakSelf = self;
    [self.imageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!error) {
            [strongSelf updateImage:image];
        }
    }];
}

- (void)updateImage:(UIImage *)image {
    // Remove any transform currently applied by the scroll view zooming.
    self.imageView.transform = CGAffineTransformIdentity;

    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);

    self.contentSize = image.size;

    [self updateZoomScale];
    [self centerScrollViewContents];
}

- (void)setupImageScrollView {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
}

- (void)updateZoomScale {
    if (self.imageView.image) {
        CGRect scrollViewFrame = self.bounds;

        CGFloat scaleWidth = scrollViewFrame.size.width / self.imageView.image.size.width;
        CGFloat scaleHeight = scrollViewFrame.size.height / self.imageView.image.size.height;
        CGFloat minScale = MIN(scaleWidth, scaleHeight);

        self.minimumZoomScale = minScale;
        self.maximumZoomScale = MAX(minScale, self.maximumZoomScale);

        self.zoomScale = self.minimumZoomScale;

        // scrollView.panGestureRecognizer.enabled is on by default and enabled by
        // viewWillLayoutSubviews in the container controller so disable it here
        // to prevent an interference with the container controller's pan gesture.
        //
        // This is enabled in scrollViewWillBeginZooming so panning while zoomed-in
        // is unaffected.
        self.panGestureRecognizer.enabled = NO;
    }
}

#pragma mark - Centering

- (void)centerScrollViewContents {
    CGFloat horizontalInset = 0;
    CGFloat verticalInset = 0;

    if (self.contentSize.width < CGRectGetWidth(self.bounds)) {
        horizontalInset = (CGRectGetWidth(self.bounds) - self.contentSize.width) * 0.5;
    }

    if (self.contentSize.height < CGRectGetHeight(self.bounds)) {
        verticalInset = (CGRectGetHeight(self.bounds) - self.contentSize.height) * 0.5;
    }

    if (self.window.screen.scale < 2.0) {
        horizontalInset = __tg_floor(horizontalInset);
        verticalInset = __tg_floor(verticalInset);
    }

    // Use `contentInset` to center the contents in the scroll view. Reasoning explained here: http://petersteinberger.com/blog/2013/how-to-center-uiscrollview/
    self.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
}

@end
