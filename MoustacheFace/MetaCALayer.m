//
//  MetaCALayer.m
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MetaCALayer.h"

@implementation MetaCALayer

@synthesize metaOriginalContentSize = _metaOriginalContentSize;


-(void)metaSetUIImageContent:(UIImage *)image{
    self.contents = (id)[image CGImage];
    _metaOriginalContentSize = image.size;
}

-(CGRect)metaSetWidth:(float)width{
    return [self metaSetWidth:width andFlip:NO];
}

-(CGRect)metaSetWidth:(float)width andFlip:(BOOL)flip{
    float scaleBy = width/self.metaOriginalContentSize.width;
    float height = self.metaOriginalContentSize.height * scaleBy;
    
    CGRect frame = self.frame;
    frame.size.width = flip ? height : width;
    frame.size.height = flip ? width : height;
    
    return self.frame = frame;    
}

-(void)metaSetFrameLeft:(float)x Top:(float)y {
    CGRect frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    self.frame = frame;
}

-(void)metaSetFrameLeft:(float)x Bottom:(float)y {
    CGRect frame = self.frame;
    frame.origin.x = x;
    frame.origin.y = y - frame.size.height;
    self.frame = frame;
}

-(void)metaSetFrameCenterX:(float)x Y:(float)y{
    CGRect frame = self.frame;
    frame.origin.x = x - self.frame.size.width/2;
    frame.origin.y = y - self.frame.size.height/2;
    self.frame = frame;
}


-(void)metaSetFrameX :(float)x Y:(float)y Origin:(MetaCALayerOrigin)origin{
    switch (origin) {
        case MetaCALayerOriginCenter:
            [self metaSetFrameCenterX:x Y:y];
            break;
        case MetaCALayerOriginLeftBottom:
            [self metaSetFrameLeft:x Bottom:y];
            break;
        case MetaCALayerOriginLeftTop:
            [self metaSetFrameLeft:x Top:y];
        default:
            break;
    }
}
@end
