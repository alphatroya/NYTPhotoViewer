//
// Created by Alexey Korolev on 07.09.15.
//

#import <Foundation/Foundation.h>
#import <NYTPhotoViewer/NYTPhoto.h>

@protocol NYTURLPhoto <NYTPhoto>

/**
*  parameter contains url to image
*/
@property(nonatomic, readonly) NSURL *photoURL;

@end