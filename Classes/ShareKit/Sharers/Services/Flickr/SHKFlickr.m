//
//  SHKTwitter.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

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

// TODO - SHKTwitter supports offline sharing, however the url cannot be shortened without an internet connection.  Need a graceful workaround for this.


#import "SHKFlickr.h"
#import "NSString+Base58.h"

static NSString *kStoredAuthTokenKeyName = @"FlickrStoredAuthTokenKeyName";
static NSString *kUploadImageStep = @"kUploadImageStep";

@interface SHKFlickr(OFFlickrAPIRequestDelegate)<OFFlickrAPIRequestDelegate>
@end

@implementation SHKFlickr

@synthesize flickrLink;
//@synthesize tags;
//@synthesize privacy;

- (id)init
{
    self = [super init];
	if (self)
	{	
		//privacy = 3;	// default public photo
	}	
	return self;
}

- (void) dealloc {
	[flickrContext release];
	[requestDialog release];
	self.flickrLink = nil;
	//self.tags = nil;
	
    [super dealloc];
}

- (OFFlickrAPIContext *)flickrContext
{
    if (!flickrContext) {
        flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:OBJECTIVE_FLICKR_API_KEY sharedSecret:OBJECTIVE_FLICKR_API_SHARED_SECRET];
        
        NSString *authToken = authToken = [[NSUserDefaults standardUserDefaults] objectForKey:kStoredAuthTokenKeyName];
        if (authToken) {
            flickrContext.authToken = authToken;
        }
    }
    
    return flickrContext;
}

- (SHKFlickrRequestDialog*) requestDialog {
    if (!requestDialog) {
        requestDialog = [[SHKFlickrRequestDialog alloc] init];
		requestDialog.flickrContext = self.flickrContext;
		requestDialog.delegate = self;
    }
    
    return requestDialog;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Flickr";
}

+ (BOOL)canShareURL
{
	return NO;
}

+ (BOOL)canShareText
{
	return NO;
}

+ (BOOL)canShareImage
{
	return YES;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare{
	return YES;
}

- (BOOL)shouldAutoShare{
	return NO;
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
    if (isAuthorized) return YES;   // connect to server already
    return [self.requestDialog login: NO];
}

- (void)promptAuthorization
{		
	[self.requestDialog login: YES];
}


#pragma mark -
#pragma mark UI Implementation

/*
- (void)show
{
	if (item.shareType == SHKShareTypeImage)
	{
		//[item setCustomValue:item.title forKey:@"status"];
		//[self showTwitterForm];
	}
}
 */

/*
- (void)showTwitterForm
{
	SHKTwitterForm *rootView = [[SHKTwitterForm alloc] initWithNibName:nil bundle:nil];	
	rootView.delegate = self;
	
	// force view to load so we can set textView text
	[rootView view];
	
	rootView.textView.text = [item customValueForKey:@"status"];
	rootView.hasAttachment = item.image != nil;
	
	[self pushViewController:rootView animated:NO];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKTwitterForm *)form
{	
	[item setCustomValue:form.textView.text forKey:@"status"];
	[self tryToSend];
}
*/

#pragma mark -
#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type{
    NSMutableArray *baseArray = [NSMutableArray arrayWithObjects:
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Tags")
                                                         key:@"tags"
                                                        type:SHKFormFieldTypeText
                                                       start:item.tags],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Private")
                                                         key:@"private"
                                                        type:SHKFormFieldTypeSwitch
                                                       start:SHKFormFieldSwitchOff],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Send to Twitter")
                                                         key:@"twitter"
                                                        type:SHKFormFieldTypeSwitch
                                                       start:SHKFormFieldSwitchOff],
                                 nil
                                 ];
    if([item shareType] == SHKShareTypeImage){
        [baseArray insertObject:[SHKFormFieldSettings label:SHKLocalizedString(@"Caption")
                                                        key:@"caption"
                                                       type:SHKFormFieldTypeText
                                                      start:nil] 
                        atIndex:0];
    }else{
        [baseArray insertObject:[SHKFormFieldSettings label:SHKLocalizedString(@"Title")
                                                        key:@"title"
                                                       type:SHKFormFieldTypeText
                                                      start:item.title]
                        atIndex:0];
    }
    return baseArray;
}

#pragma mark Share API Methods

/*
- (BOOL)validate
{
	NSString *status = [item customValueForKey:@"status"];
	return status != nil && status.length >= 0 && status.length <= 140;
}

- (BOOL)send
{	
	// Check if we should send follow request too
	if (xAuth && [item customBoolForSwitchKey:@"followMe"])
		[self followMe];	
	
	if (![self validate])
		[self show];
	
	else
	{	
		if (item.shareType == SHKShareTypeImage) {
			[self sendImage];
		} else {
			[self sendStatus];
		}
		
		// Notify delegate
		[self sendDidStart];	
		
		return YES;
	}
	
	return NO;
}
 */
- (void) sendImage {
	
	UIImage *image = item.image;
	NSData *JPEGData = UIImageJPEGRepresentation(image, 0.8);	
	self.requestDialog.flickrRequest.delegate = self;
	self.requestDialog.flickrRequest.sessionInfo = kUploadImageStep;
    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithCapacity:3];
    int privacy = 3;
    
    privacy = [item customBoolForSwitchKey:@"private"] ? 1 : 3;
    
    switch (privacy) {
        case 1:
            [args setObject:@"1" forKey:@"is_family"]; break;
        case 2:
            [args setObject:@"2" forKey:@"is_friend"]; break;
        case 3:
            [args setObject:@"3" forKey:@"is_public"]; break;
    }
    
    NSString *description = [item customValueForKey:@"caption"];    
    if (description) [args setObject:description forKey:@"description"];
    
    NSString *tags = [item tags];
    if (tags) [args setObject:tags forKey:@"tags"];
	[self.requestDialog.flickrRequest uploadImageStream:[NSInputStream inputStreamWithData:JPEGData] suggestedFilename:item.title MIMEType:@"image/jpeg" arguments:args];
}

- (BOOL) send {
	if ([self validateItem]) {
		if (item.shareType == SHKShareTypeImage) {
			[self sendImage];
            
            [self sendDidStart];
            
            return YES;
        }
    }    
    return NO;
}


#pragma mark OFFlickrAPIRequest delegate methods
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, inRequest.sessionInfo, inResponseDictionary);
	if (inRequest.sessionInfo == kUploadImageStep) {
		NSString *photoID = [[inResponseDictionary valueForKeyPath:@"photoid"] textContent];
		//NSLog(@"shorten url = http://flic.kr/p/%@", [NSString base58_Encode:[photoID longLongValue]]);
		self.flickrLink = [NSString stringWithFormat:@" http://flic.kr/p/%@", [NSString base58_Encode:[photoID longLongValue]]];
        
	}	
	/*
	else if (inRequest.sessionInfo == kGetPhotoURLStep) {
		NSString *url = [[[[[inResponseDictionary objectForKey:@"photo"] objectForKey:@"urls"] objectForKey:@"url"] objectAtIndex:0] objectForKey:@"_text"];
		NSLog(@"%@", url);
		
	}
	 */
	[self sendDidFinish];
	
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
#if 0
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, inRequest.sessionInfo, inError);
	if (inRequest.sessionInfo == kUploadImageStep) {
		[self updateUserInterface:nil];
		snapPictureDescriptionLabel.text = NSLocalizedString(@"Failed", @"label");		
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		
		[[[[UIAlertView alloc] initWithTitle:@"API Failed" message:[inError description] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
		
	}
	else {
		[[[[UIAlertView alloc] initWithTitle:@"API Failed" message:[inError description] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
	}
#endif
	[self sendDidFailWithError:inError];	
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes
{
	// progress
#if 0
	if (inSentBytes == inTotalBytes) {
		snapPictureDescriptionLabel.text = @"Waiting for Flickr...";
	}
	else {
		snapPictureDescriptionLabel.text = [NSString stringWithFormat:@"%lu/%lu (KB)", inSentBytes / 1024, inTotalBytes / 1024];
	}
#endif
}

#pragma mark authoize

-(void) flickrAuthorize:(SHKFlickrRequestDialog*)dialog didComplete:(OFFlickrAPIContext*)context {
    
//Error: share will call authorize that will call flickr to authorize again...
    isAuthorized = YES;
	[self share];
}

/* failed to authorize */
-(void) flickrAuthorize:(SHKFlickrRequestDialog*)dialog didFailWithError:(NSError*) error {
}

@end
