//
//  MetaCALayer.h
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

typedef enum {
    MetaCALayerOriginCenter,
    MetaCALayerOriginLeftTop,
    MetaCALayerOriginLeftBottom
} MetaCALayerOrigin;

@interface MetaCALayer : CALayer

@property (nonatomic, readonly) CGSize metaOriginalContentSize;

-(void)metaSetUIImageContent:(UIImage *)image;
-(CGRect)metaSetWidth:(float)width;
-(CGRect)metaSetWidth:(float)width andFlip: (BOOL)flip;

-(void)metaSetFrameX:(float)x Y:(float)y Origin:(MetaCALayerOrigin) origin;

-(void)metaSetFrameLeft: (float) x Top:(float) y;
-(void)metaSetFrameLeft: (float) x Bottom:(float) y;
-(void)metaSetFrameCenterX:(float) x Y:(float)y;


@end
