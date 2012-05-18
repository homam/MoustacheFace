//
//  FaceMask.h
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import<QuartzCore/QuartzCore.h>
#import "MetaCALayer.h"

typedef float (^FaceFeatureDescriptorAdjuster)(CIFaceFeature * face, CGSize featureSize, CGRect transformedFaceRect);
typedef CGRect (^FaceFeatureRectConverter)(CGRect faceRect);

@interface FaceDescriptor : NSObject

/*-(id) initWithWidthRatioOfFace:
    (float)widthRatioOfFace
     andOrigin: (MetaCALayerOrigin) origin;
*/
-(id)initWithWidthRatioOfFace:
    (float)widthRatioOfFace 
     andOrigin: (MetaCALayerOrigin) origin
     andXAdjuster:(FaceFeatureDescriptorAdjuster) xAdjuster 
     andYAdjuster:(FaceFeatureDescriptorAdjuster) yAdjuster;

@property (nonatomic) MetaCALayerOrigin origin;
@property (nonatomic) float widthRatioOfFace;
//@property (nonatomic, weak) MetaCALayer *featureLayer;
@property (nonatomic, strong) FaceFeatureDescriptorAdjuster xAdjuster;
@property (nonatomic, strong) FaceFeatureDescriptorAdjuster yAdjuster;
-(void)adjustLayer: (MetaCALayer *)layer withFace: (CIFaceFeature *)face transformedFaceRect:(CGRect) faceRect rectConverter:(FaceFeatureRectConverter) converter;


//+(FaceFeatureDescriptorAdjuster) faceFeatureDescriptorAdjusterIdentity;


@end

@interface FaceFeatureDescriptor : FaceDescriptor

@end
