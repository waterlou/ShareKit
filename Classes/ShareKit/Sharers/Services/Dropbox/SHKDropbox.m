//
//  SHKTwitter.m
//  ShareKit
//
//  Created by Water Lou on 05/26/2011.

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


#import "SHKDropbox.h"

@implementation SHKDropbox

- (id)init
{
	self = [super init];
	if (self) {	
		// setup the session
		DBSession* session = 
		[[DBSession alloc] initWithConsumerKey:kDropboxConsumerKey consumerSecret:kDropboxConsumerSecret];
		session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
		[DBSession setSharedSession:session];
		[session release];		
	}	
	return self;
}

- (DBRestClient*)restClient {
    if (restClient == nil) {
    	restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    	restClient.delegate = self;
    }
    return restClient;
}

- (void) dealloc {
	[restClient release];
	[super dealloc];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Dropbox";
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

+ (BOOL)canShareFile
{
	return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable


#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
    return [[DBSession sharedSession] isLinked];
}

- (void)promptAuthorization
{		
	DBLoginController* controller = [[[DBLoginController alloc] init] autorelease];
	controller.delegate = self;
	[self pushViewController:controller animated:NO];	
	[[SHK currentHelper] showViewController:self];	
}

+ (void)logout {
	DBSession* session = 
	[[DBSession alloc] initWithConsumerKey:kDropboxConsumerKey consumerSecret:kDropboxConsumerSecret];
	[session unlink];
	[session release];		
}

#pragma mark DBLoginControllerDelegate methods

- (void)loginControllerDidLogin:(DBLoginController*)controller {
	[self share];
}

- (void)loginControllerDidCancel:(DBLoginController*)controller {	
}

#pragma mark DBSessionDelegate

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session {
}

#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath {
	[self sendDidFinish];	
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
	[self sendDidFailWithError:error];	
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL) sendImage {
	UIImage *image = item.image;
	NSData *JPEGData = UIImageJPEGRepresentation(image, 0.8);
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle: NSDateFormatterMediumStyle];
	[formatter setTimeStyle: NSDateFormatterShortStyle];
	//NSLog(@"date %@", [formatter stringFromDate:[NSDate date]]);
	NSString *filename = [NSString stringWithFormat: @"%@ - %@.jpg", (self.title ? self.title : @"Unnamed"), [formatter stringFromDate:[NSDate date]]];
	[[self restClient] uploadFile:filename toPath:@"/Photos" fromPath:filename fromData: JPEGData];
	[formatter release];
	return YES;
}

- (BOOL) sendFile {
	NSData *data = item.data;
	[[self restClient] uploadFile:item.filename toPath:@"/" fromPath:item.filename fromData: data];
	return NO;
}

- (BOOL)send
{	
	if (item.shareType == SHKShareTypeImage) {
		[self sendImage];
		// Notify delegate
		[self sendDidStart];	
		return YES;
	} else {
		[self sendFile];
		// Notify delegate
		[self sendDidStart];	
		return YES;
	}
	return NO;
}


@end
