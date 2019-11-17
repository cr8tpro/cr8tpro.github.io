//
//  RTMPStream.h
//  PunditsTutor
//
//  Created by Rinat K on 16.09.15.
//  Copyright (c) 2015 Developer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@interface RTMPStream : NSObject

- (void)startPublishForTutorId:(NSString*)tId questionId:(NSString*)qId;
- (void)stopPublish;
- (void)sendImageFrame:(UIImage*)image;

@end
