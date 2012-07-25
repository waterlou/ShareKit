//
//  SHKSSOFacebook.m
//  ShareKit
//
//  Created by Water Lou on 02/01/12.

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

#import "SHKSSOFacebook.h"

static NSString *const SHKFacebookPendingItem = @"SHKFacebookPendingItem";

@implementation SHKSSOFacebook

- (Facebook*)facebook {
    // get the facebook object from UIApplication delegate
    return [ [ [UIApplication sharedApplication] delegate ] performSelector: @selector(facebook) ];
}

- (void)promptAuthorization {
    // store the pending item in NSUserDefaults as the authorize could kick the user out to the Facebook app or Safari
    [[NSUserDefaults standardUserDefaults] setObject:[self.item dictionaryRepresentation] forKey:SHKFacebookPendingItem];
    
    // TODO: click off SSO
    id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
    [delegate performSelector:@selector(authorizeFacebook:delegate:) withObject: permissions withObject:self];
}

- (void) application : (id<UIApplicationDelegate>)delegate facebookLoginSucceeded : (Facebook*)facebook {
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

- (void)authFinished:(SHKRequest*)request {
    
}

+ (void)logout {
    Facebook *fb = [ [ [UIApplication sharedApplication] delegate ] performSelector: @selector(facebook) ];
	[fb logout: (NSObject<FBSessionDelegate> *)[[UIApplication sharedApplication] delegate]];
}

@end

