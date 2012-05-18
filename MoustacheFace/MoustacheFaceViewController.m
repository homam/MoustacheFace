//
//  MoustacheFaceViewController.m
//  MoustacheFace
//
//  Created by Homam Hosseini on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MoustacheFaceViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MetaCALayer.h"
#import "MasksTableView.h"
#import "FaceMask.h"
#import "FaceFeatureAddOn.h"


@interface MoustacheFaceViewController ()

+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize;

@property (nonatomic, strong) AVCaptureSession *sessoin;
@property (strong) AVCaptureDevice *videoDevice;
@property (strong) AVCaptureDeviceInput *videoInput;
@property (strong) AVCaptureVideoDataOutput *frameOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) IBOutlet UIView *imageView;

@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) CIContext *context;

@property (nonatomic, strong) UIImageView *glasses;

@property (nonatomic) dispatch_queue_t liveImageProcQueue;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;

@property (nonatomic, strong) NSDictionary *addOnsDic;
@property (weak, nonatomic) IBOutlet UIView *masksView;
- (IBAction)startButtonTapped:(id)sender;

@end


@implementation MoustacheFaceViewController

@synthesize sessoin = _sessoin;
@synthesize videoInput = _videoInput;
@synthesize videoDevice = _videoDevice;
@synthesize frameOutput = _frameOutput;
@synthesize previewLayer = _previewLayer;
@synthesize imageView = _imageView;
@synthesize faceDetector = _faceDetector;
@synthesize context = _context;
@synthesize glasses = _glasses;
@synthesize liveImageProcQueue = _liveImageProcQueue;
@synthesize statusLabel = _statusLabel;
@synthesize statusImageView = _statusImageView;

@synthesize addOnsDic = _addOnsDic;
@synthesize masksView = _masksView;


-(CIContext *) context {
    if(!_context){
        _context = [CIContext contextWithOptions:nil];
    }
    return _context;
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
    
    
    NSArray *features = [self.faceDetector featuresInImage:ciImage options:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[self getDeviceExifOrientation]] forKey:CIDetectorImageOrientation]];
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self drawFeatures:features inBox:clap];
    });
        

    
    CIFilter *filter = [CIFilter filterWithName:@"CIHueAdjust"];
    [filter setDefaults];
    [filter setValue:ciImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:2.0] forKey:@"inputAngle"];
    
    CIImage *resultCIImage = [filter valueForKey:@"outputImage"];
         //resultCIImage = [resultCIImage imageByApplyingTransform:CGAffineTransformMakeScale(1, -1)];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        CGImageRef cgImage = [self.context createCGImage:resultCIImage fromRect:ciImage.extent];
        self.statusImageView.image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
        CGImageRelease(cgImage);
    });
    
}

-(void)drawFeatures:(NSArray *)features inBox:(CGRect)aperture {
    
    typedef MetaCALayer * (^GetLayer)(NSString *layerName, FaceFeatureAddOn *addOn);
    
    GetLayer getLayer = ^(NSString *layerName, FaceFeatureAddOn *addOn) {
        
        __block MetaCALayer *layer0 = nil;
        
        NSArray *sublayers = self.imageView.layer.sublayers;
        [sublayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            MetaCALayer *l = (MetaCALayer *)obj;
            if(l.name == layerName)
            {
                layer0 = l;
                *stop = YES;
            }
        }];
        
        
        if(!layer0){
            UIImage *content = addOn ? addOn.image : nil;
            layer0 = [MetaCALayer new];
            layer0.name = layerName;
            if(!content) {
                layer0.backgroundColor = [[UIColor colorWithRed:arc4random_uniform(10)/10.0 green:arc4random_uniform(10)/10.0 blue:arc4random_uniform(10)/10.0 alpha:.6] CGColor];
            } else {
                [layer0 metaSetUIImageContent:content];
            }
            layer0.frame = CGRectMake(10, 10,  100, 100);
            [self.imageView.layer addSublayer:layer0];
        } 
        
        
        return  layer0;
    };
    
    FaceFeatureAddOn *eyePatchAddOn = [self.addOnsDic valueForKey:@"eyePatch"];
    MetaCALayer *layerEyePatch = getLayer(@"layerEyePatch",eyePatchAddOn);
    CALayer *layer1 = getLayer(@"layer1",nil);
    layer1.hidden = YES;
    FaceFeatureAddOn *moustacheAddOn = [self.addOnsDic valueForKey:@"moustache"];
    MetaCALayer *layerMoustache = getLayer(@"layerMoustache",moustacheAddOn);
    FaceFeatureAddOn *hatAddOn = [self.addOnsDic valueForKey:@"uncleSAMhat"];
    MetaCALayer *layerHat = getLayer(@"layerHat",hatAddOn);
    
    

    
    


    [CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
   
    CGSize parentFrameSize = [self.imageView frame].size;
    NSString *gravity = self.previewLayer.videoGravity;
    BOOL isMirrored = YES;// [self.previewLayer isMirrored];
    if(!gravity)gravity = AVLayerVideoGravityResizeAspect;

    CGRect previewBox = [MoustacheFaceViewController videoPreviewBoxForGravity:gravity frameSize:parentFrameSize apertureSize:aperture.size];

        
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = previewBox.size.width / aperture.size.height;
    CGFloat heightScaleBy = previewBox.size.height / aperture.size.width;
    
    self.statusLabel.text = [NSString stringWithFormat:@"%@", eyePatchAddOn ];//NSStringFromCGRect(previewBox)
    
    typedef CGRect (^FaceRectConverter)(CGRect faceRect);
    FaceRectConverter convertCGRect = ^(CGRect faceRect) {


        // flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
        
		// scale coordinates so they fit in the preview box, which may be scaled
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
        
        if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
         
        
        return faceRect;  
    };
    
    
    for(CIFaceFeature *face in features){
        
        CGRect originalFaceRect = [face bounds];
		CGRect faceRect = [face bounds];
        
        
        faceRect = convertCGRect(faceRect);
        
        [eyePatchAddOn.descriptor adjustLayer: layerEyePatch withFace: face transformedFaceRect:faceRect rectConverter:convertCGRect];
        [moustacheAddOn.descriptor adjustLayer: layerMoustache withFace: face transformedFaceRect:faceRect rectConverter:convertCGRect];
        [hatAddOn.descriptor adjustLayer: layerHat withFace: face transformedFaceRect:faceRect rectConverter:convertCGRect];
        
        //[eyePatchDescriptor adjustLayer:face.leftEyePosition faceRect:originalFaceRect rectConverter:convertCGRect];
        //[moustacheDescriptor adjustLayer:face.mouthPosition faceRect:originalFaceRect rectConverter:convertCGRect];
        //
        //[hatDescriptor adjustLayer:faceRect.origin faceRect:faceRect rectConverter:convertCGRect];
        
        layer1.frame = convertCGRect(CGRectMake(face.rightEyePosition.x - 10, face.rightEyePosition.y - 15, 20, 30));


    }
    
    [CATransaction commit];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    /*
    NSArray *addonNames = [NSArray arrayWithObjects:@"eyePatch", @"uncleSAMhat", @"moustache", @"phantom1", nil];
    NSMutableDictionary *addonsDic = [[NSMutableDictionary alloc]initWithCapacity:addonNames.count];
    for(id name in addonNames){
        [addonsDic setValue:[UIImage imageNamed:name] forKey:name];
    }
    self.addonImages = addonsDic ;*/
    
    NSMutableDictionary __block *addonsDic = [[NSMutableDictionary alloc]initWithCapacity:4];
    
    void (^addFaceFeatureAddOn) (NSString *, FaceDescriptor *) = ^(NSString * identifier, FaceDescriptor * descriptor)  {
        FaceFeatureAddOn *addOn = [[FaceFeatureAddOn alloc]initWithID:identifier andImage:[UIImage imageNamed:identifier] andDescriptor:descriptor];
        [addonsDic setValue:addOn forKey:identifier];
    };
    
    

    
    FaceFeatureDescriptor *eyePatchDescriptor = [[FaceFeatureDescriptor alloc]initWithWidthRatioOfFace:.5 andOrigin:MetaCALayerOriginCenter
                                                                                          andXAdjuster:^float(CIFaceFeature *face, CGSize featureSize, CGRect transformedFaceRect) {
                                                                                              return face.leftEyePosition.x - featureSize.width*.15;
                                                                                          } andYAdjuster:^float(CIFaceFeature *face, CGSize featureSize, CGRect transformedFaceRect) {
                                                                                              return face.leftEyePosition.y;
                                                                                          }];
    addFaceFeatureAddOn(@"eyePatch", eyePatchDescriptor);
    

    FaceFeatureDescriptor *moustacheDescriptor = [[FaceFeatureDescriptor alloc] initWithWidthRatioOfFace:.7 andOrigin:MetaCALayerOriginCenter 
                                                                                            andXAdjuster:^float(CIFaceFeature *face, CGSize featureSize, CGRect transformedFaceRect) {
                                                                                                return face.mouthPosition.x - featureSize.width*.25;
                                                                                            } andYAdjuster:^float(CIFaceFeature *face, CGSize featureSize, CGRect faceSize) {
                                                                                                return face.mouthPosition.y;
                                                                                            }];
    addFaceFeatureAddOn(@"moustache", moustacheDescriptor);
    
    FaceDescriptor *hatDescriptor = [[FaceDescriptor alloc] initWithWidthRatioOfFace:1.2 
                                                                           andOrigin:MetaCALayerOriginLeftBottom
                                                                        andXAdjuster:^float(CIFaceFeature * face, CGSize featureSize, CGRect transformedFaceRect) {
                                                                            return transformedFaceRect.origin.x-(featureSize.width -transformedFaceRect.size.width)*.5;
                                                                        } 
                                                                        andYAdjuster:^float(CIFaceFeature *face, CGSize featureSize, CGRect transformedFaceRect) {
                                                                            return transformedFaceRect.origin.y - transformedFaceRect.size.height*.2;
                                                                        }];
    addFaceFeatureAddOn(@"uncleSAMhat", hatDescriptor);
    
    self.addOnsDic = addonsDic;
    MasksTableView *v = [self.masksView.subviews objectAtIndex:0];
    v.maskImagesDic = addonsDic;
    v.dataSource = v;
    [v reloadData];
    
    //NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"MasksViews" owner:self options:nil];
    //[self.masksView addSubview:[nibViews objectAtIndex:0]];  // Retains the
}

- (void)viewDidUnload
{
    dispatch_release(self.liveImageProcQueue);

    [self setStatusLabel:nil];
    [self setStatusImageView:nil];
    [self setMasksView:nil];
    [super viewDidUnload];
}


- (IBAction)startButtonTapped:(id)sender {
    
    self.liveImageProcQueue = dispatch_queue_create("liveImageProcQueue", NULL);        
    
    self.sessoin = [[AVCaptureSession alloc] init];
    self.sessoin.sessionPreset = AVCaptureSessionPreset352x288;
    
    
    // try to find the front facing camera
    __block AVCaptureDevice *selectedCaptureDevice = nil;
    
    [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        AVCaptureDevice *d = (AVCaptureDevice *)obj;
        if([d position] == AVCaptureDevicePositionFront){
            selectedCaptureDevice = d;
            *stop = YES;
        }
    }];
    
    // fallback to the default camera if no front facing camera was found
    if(!selectedCaptureDevice)
        selectedCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    self.videoDevice = selectedCaptureDevice; 
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
    
    self.frameOutput = [[AVCaptureVideoDataOutput alloc]init];
    self.frameOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.frameOutput setSampleBufferDelegate:self queue:self.liveImageProcQueue];
    
    [self.sessoin addInput:self.videoInput];
    [self.sessoin addOutput:self.frameOutput];
    
    
    AVCaptureVideoPreviewLayer* previewLayer = self.previewLayer;
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.sessoin];
	[previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	CALayer *rootLayer = [self.imageView layer];
    rootLayer.masksToBounds = YES;
    previewLayer.frame = rootLayer.bounds;
    previewLayer.bounds = previewLayer.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	[rootLayer addSublayer:previewLayer];
    
    NSDictionary *detectorOptions= [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    //_faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.context options:detectorOptions];
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.context options:detectorOptions];
    
    [self.sessoin startRunning];
}

- (void)dealloc
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(int)getDeviceExifOrientation {
    
    BOOL isUsingFrontFacingCamera = self.videoDevice.position == AVCaptureDevicePositionFront;
    
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants. 
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.  
	};
	
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    return exifOrientation;
}


// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

@end
