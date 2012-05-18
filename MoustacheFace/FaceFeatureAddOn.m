//
//  FaceFeatureAddOn.m
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FaceFeatureAddOn.h"

@implementation FaceFeatureAddOn

@synthesize descriptor = _descriptor;
@synthesize image = _image;
@synthesize identifier = _identifier;

-(id)initWithID: (NSString *) identifier andImage:(UIImage *)image andDescriptor:(FaceDescriptor *)descriptor {
    self = [super init];
    self.identifier = identifier;
    self.image = image;
    self.descriptor = descriptor;
    return self;
}

@end
