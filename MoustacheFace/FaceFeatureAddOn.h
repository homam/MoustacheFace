//
//  FaceFeatureAddOn.h
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceMask.h"

@interface FaceFeatureAddOn : NSObject

-(id)initWithID: (NSString *) identifier andImage: (UIImage *)image andDescriptor: (FaceDescriptor *) descriptor;

@property (nonatomic, strong) FaceDescriptor *descriptor;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) NSString *identifier;

@end
