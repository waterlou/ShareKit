//
//  SHKFacebook.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKFacebook.h"
#import "SHKFacebookForm.h"

@implementation SHKFacebook

@synthesize pendingFacebookAction;

static NSString *const SHKFacebookAccessToken = @"SHKFacebookAccessToken";
static NSString *const SHKFacebookExpirationDate = @"SHKFacebookExpirationDate";
static NSString *const SHKFacebookPendingItem = @"SHKFacebookPendingItem";

- (id)init {
    if ((self = [super init] )) {
		permissions = [[NSArray alloc] initWithObjects:@"publish_stream", @"offline_access", nil];
	}
    
	return self;
}

- (void)dealloc {
	[_facebook release], _facebook = nil;
    [permissions release];
	[super dealloc];
}

- (Facebook*)facebook {
	if (!_facebook) {
		_facebook = [[Facebook alloc] initWithAppId:SHKFacebookAppID];
		_facebook.sessionDelegate = self;
		_facebook.accessToken = [self getAuthValueForKey:SHKFacebookAccessToken];
		_facebook.expirationDate = (NSDate*)[[NSUserDefaults standardUserDefaults] objectForKey:SHKFacebookExpirationDate];
	}
    
	return _facebook;
}

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString*)sharerTitle {
	return @"Facebook";
}

+ (BOOL)canShareURL {
	return YES;
}

+ (BOOL)canShareText {
	return YES;
}

+ (BOOL)canShareImage {
	return YES;
}

+ (BOOL)canShareOffline {
	return NO;  // TODO - would love to make this work
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare {
    if (SHKFacebookShowDialog) return NO;   // disable autoShare    
	return YES; // FBConnect presents its own dialog
}

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized {    
	return [self.facebook isSessionValid];
}

- (void)promptAuthorization {
    
    // We mod the facebook API so that won't kick out of our app, because we can't store image in UserDefaults
    /*
     // store the pending item in NSUserDefaults as the authorize could kick the user out to the Facebook app or Safari
     [[NSUserDefaults standardUserDefaults] setObject:[self.item dictionaryRepresentation] forKey:SHKFacebookPendingItem];
     */
	[self.facebook authorize:permissions delegate:self singleSignOn: NO];
}

- (void)authFinished:(SHKRequest*)request {
}

+ (void)logout {
	Facebook *fb = [[[Facebook alloc] initWithAppId:SHKFacebookAppID] autorelease];
	fb.accessToken = [[[[self alloc] init] autorelease] getAuthValueForKey:SHKFacebookAccessToken];
	fb.expirationDate = (NSDate*)[[NSUserDefaults standardUserDefaults] objectForKey:SHKFacebookExpirationDate];
	[fb logout:self];
    
	[SHK removeAuthValueForKey:SHKFacebookAccessToken forSharer:[self sharerId]];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKFacebookExpirationDate];
}

#pragma mark -
#pragma mark Share API Methods

- (void)show {
#if SHKFacebookShowDialog    
    [self showFacebookForm];
#else 
    [super show];   // default action
#endif
}

- (BOOL)send {
	if (item.shareType == SHKShareTypeURL) {
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [item.URL absoluteString], @"link",
									   item.title, @"name",
									   item.text, @"caption",
									   nil];
        
		if ([item customValueForKey:@"image"]) {
			[params setObject:[item customValueForKey:@"image"] forKey:@"picture"];
		}
        NSString *message = [item customValueForKey:@"message"];
        if (message==nil || message.length==0) {
            message = item.title;
        }
        [params setObject:message forKey:@"message"];
        
		[self.facebook requestWithGraphPath:@"me/feed" 
								  andParams:params 
							  andHttpMethod:@"POST" 
								andDelegate:self];
	}
	else if (item.shareType == SHKShareTypeText) {
		NSString *actionLinks = [NSString stringWithFormat:@"{\"name\":\"Get %@\", \"link\":\"%@\"}",
								 SHKEncode(SHKMyAppName),   // bug here, space will become %20 should fix it
								 SHKEncode(SHKMyAppURL)];
        
        NSString *message = [item customValueForKey:@"message"];
        if (message==nil || message.length==0) {
            message = item.text;
        }
        
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   message, @"message",
									   actionLinks, @"actions",
									   nil];
        
        
		[self.facebook requestWithGraphPath:@"me/feed" 
								  andParams:params 
							  andHttpMethod:@"POST" 
								andDelegate:self];
	}
	else if (item.shareType == SHKShareTypeImage) {
        NSString *caption = [item customValueForKey:@"message"];
        if (caption==nil || caption.length==0) {
            caption = item.title;
        }
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       item.image, @"picture",
                                       caption, @"caption",
                                       nil];
        [_facebook requestWithMethodName:@"photos.upload"
                               andParams:params
                           andHttpMethod:@"POST"
                             andDelegate:self];
        
        /*        
         NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
         item.image, @"source",
         item.title, @"message",
         nil];
         
         [self.facebook requestWithGraphPath:@"me/photos" 
         andParams:params 
         andHttpMethod:@"POST" 
         andDelegate:self];
         */
	}
    
	[self sendDidStart];
    
	return YES;
}

- (void)dialogDidComplete:(FBDialog *)dialog {
	if (pendingFacebookAction == SHKFacebookPendingStatus) {
		[self sendDidFinish];
	}
}

- (void)dialogDidNotComplete:(FBDialog *)dialog {
	if (pendingFacebookAction == SHKFacebookPendingStatus) {
		[self sendDidCancel];
	}
}

- (BOOL)dialog:(FBDialog *)dialog shouldOpenURLInExternalBrowser:(NSURL *)url {
	return YES;
}

#pragma mark -
#pragma mark FBSessionDelegate methods
- (void)fbDidLogin {
	// store the Facebook credentials for use in future requests
	[SHK setAuthValue:self.facebook.accessToken forKey:SHKFacebookAccessToken forSharer:[self sharerId]];
	[[NSUserDefaults standardUserDefaults] setObject:self.facebook.expirationDate forKey:SHKFacebookExpirationDate];
    
	// if the current device does not support multitasking, the shared item will still be set and we can skip restoring the item
	// if the current device does support multitasking, this instance of SHKFacebook will be different that the original one and we need to restore the shared item
	UIDevice *device = [UIDevice currentDevice];
	if ([device respondsToSelector:@selector(isMultitaskingSupported)] && [device isMultitaskingSupported]) {
        NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:SHKFacebookPendingItem];
        if (dictionary) {
            self.item = [SHKItem itemFromDictionary:dictionary];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKFacebookPendingItem];
        }
	}
    
	[self share];
}

- (void)fbDidNotLogin:(BOOL)cancelled {
	// not handling this
}

- (void)fbDidLogout {
	// not handling this
}

#pragma mark -
#pragma mark FBRequestDelegate methods

- (void)request:(FBRequest*)aRequest didLoad:(id)result {
	[self sendDidFinish];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
	[self sendDidFailWithError:error];
}

#pragma mark -

- (void)showFacebookForm
{
	SHKFacebookForm *rootView = [[SHKFacebookForm alloc] initWithNibName:nil bundle:nil];	
	rootView.delegate = self;
	
	// force view to load so we can set textView text
	[rootView view];
	
    if (item.shareType == SHKShareTypeText) {
        rootView.textView.text = item.text;
    }
    else {
#if SHKFacebookTitleAsDefaultMessage
        rootView.textView.text = item.title;
#else
        rootView.textView.text = nil;
#endif
    }
	rootView.hasAttachment = item.image != nil;
	
	[self pushViewController:rootView animated:NO];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKFacebookForm *)form
{	
	[item setCustomValue:form.textView.text forKey:@"message"];
	[self tryToSend];
}

@end

