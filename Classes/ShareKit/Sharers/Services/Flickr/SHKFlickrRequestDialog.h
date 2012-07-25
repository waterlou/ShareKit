//
//  TwitterRequestDialog.h
//  fwRTHK01
//
//  Created by Water Lou on 31/03/2010.
//  Copyright 2010 First Water Tech Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKFBLikeDialog.h"
#import "ObjectiveFlickr.h"

@class SHKFlickrRequestDialog;
@protocol OFFlickrAPIRequestDelegate;

@protocol SHKFlickrRequestDialogControllerDelegate<NSObject>

-(void) flickrAuthorize:(SHKFlickrRequestDialog*)dialog didComplete:(OFFlickrAPIContext*)context;
-(void) flickrAuthorize:(SHKFlickrRequestDialog*)dialog didFailWithError:(NSError*) error;

@end

@interface SHKFlickrRequestDialog : SHKFBLikeDialog <OFFlickrAPIRequestDelegate> {
	NSString *callbackSuccessURLString;
	NSString *callbackFailURLString;
	
	OFFlickrAPIContext *flickrContext;
	OFFlickrAPIRequest *flickrRequest;
	
	id<SHKFlickrRequestDialogControllerDelegate> delegate;
}

@property (nonatomic, retain) OFFlickrAPIContext *flickrContext;
@property (nonatomic, retain) OFFlickrAPIRequest *flickrRequest;

@property (nonatomic, assign) id<SHKFlickrRequestDialogControllerDelegate> delegate;

-(BOOL) login : (BOOL) promptForLogin;

- (void)setAndStoreFlickrAuthToken:(NSString *)inAuthToken;

@end
