//
//  ViewController.m
//  CIBugTest
//
//  Created by Alexander Gingell on 12/11/2017.
//  Copyright © 2017 Horsie in the Hedge LLP. All rights reserved.
//

#import "ViewController.h"
@import CoreImage;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) CIContext *context;
@property (strong, nonatomic) NSMutableArray *animationImages;

@end

@implementation ViewController

#pragma mark Compositing

- (IBAction)performCompositeButtonTouchUpInside:(id)sender
{
    // 1. Create CIContext
    [self refreshContext];

    // 2. Prepare to receive animation images
    [self setAnimationImages:[NSMutableArray arrayWithCapacity:48]];
    
    // 2. Compositing Loop
    for (int i=0; i<48; i++)
    {
        // Load base image as CIImage
        UIImage *baseImage = [UIImage imageNamed:@"Landscape.jpg"];
        CIImage *baseCore = [CIImage imageWithCGImage:[baseImage CGImage]];
        
        // Load overlay image as CIImage
        NSString *filename = [NSString stringWithFormat:@"Hearts_%@%zd.jpg",i<10?@"0":@"",i];
        UIImage *overlayImage = [UIImage imageNamed:filename];
        CIImage *overlayCore = [CIImage imageWithCGImage:[overlayImage CGImage]];
        
        // Apply CIDisplacementDistortion
        CIFilter *filter = [CIFilter filterWithName:@"CIDisplacementDistortion"];
        [filter setValue:overlayCore forKey:@"inputDisplacementImage"];
        [filter setValue:baseCore forKey:@"inputImage"];
        [filter setValue:@([baseCore extent].size.width) forKey:@"inputScale"];
        CIImage *compositeCore = filter.outputImage;
        
        // Convert to UIImage and bank in array
        UIImage *finalImage = [self imageWithCIImage:compositeCore];
        if (finalImage) { [self.animationImages addObject:finalImage]; }
        else { NSLog(@"Image %zd failed to render",i); }
    }
    
    // Load image sequence into imageView for assessment
    [self.imageView setAnimationImages:self.animationImages];
    [self.imageView setAnimationDuration:2];
    [self.imageView setAnimationRepeatCount:0];
    [self.imageView startAnimating];
}

#pragma mark Core Image Helper

- (void) refreshContext
{
    // Regular
    [self setContext:[CIContext contextWithOptions:nil]];

    /*
    // GLES2
    NSDictionary *options = @{kCIContextWorkingColorSpace:[NSNull null], kCIContextOutputColorSpace:[NSNull null]};
    EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [self setContext:[CIContext contextWithEAGLContext:glContext options:options]];
    */
}

#pragma mark Image Conversion

- (UIImage *) imageWithCIImage:(CIImage *)imageCore
{
    // Render a UIImage from a CIImage construct
    //(See http://stackoverflow.com/a/7797578/1318452 )
    if (!imageCore) { return nil; }
    CGImageRef resultRef = [self.context createCGImage:imageCore fromRect:[imageCore extent]];
    UIImage *result = opaqueImageWithCGImage(resultRef);
    //UIImage *result = [UIImage imageWithCGImage:resultRef];
    CGImageRelease(resultRef);
    return result;
}

static UIImage * opaqueImageWithCGImage(CGImageRef imageRef)
{
    CGRect rect = CGRectMake(0.f, 0.f, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       rect.size.width,
                                                       rect.size.height,
                                                       CGImageGetBitsPerComponent(imageRef),
                                                       CGImageGetBytesPerRow(imageRef),
                                                       CGImageGetColorSpace(imageRef),
                                                       kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little // more memory efficient - seems to be the preferred format for the GPU and images are not shown as copied by core animation in simulator
                                                       //kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Little // images appear copied in simulator
                                                       );
    CGContextDrawImage(bitmapContext, rect, imageRef);
    
    CGImageRef opaqueImageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage* opaqueImage = [UIImage imageWithCGImage:opaqueImageRef
                                               scale:1
                                         orientation:UIImageOrientationUp];
    CGImageRelease(opaqueImageRef);
    CGContextRelease(bitmapContext);
    return opaqueImage;
}

@end
