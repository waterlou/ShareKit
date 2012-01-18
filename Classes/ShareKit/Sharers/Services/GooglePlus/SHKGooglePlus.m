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

#import "SHKGooglePlus.h"

@implementation SHKGooglePlus

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString*)sharerTitle {
	return @"Google Plus";
}

+ (BOOL)canShareURL {
	return YES;
}

+ (BOOL)canShareText {
	return YES;
}

+ (BOOL)canShareImage {
	return NO;
}

+ (BOOL)canShareOffline {
	return NO;  // TODO - would love to make this work
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare {
    return YES;
}

- (BOOL) authorize {
    return YES; // no need to authorize
}

- (BOOL)send {
	[self sendDidStart];
    
	if (item.shareType == SHKShareTypeURL) {
        NSString *text = [NSString stringWithFormat: @"%@ %@", item.title, item.URL.absoluteString];
        NSURL *launchUrl = [NSURL URLWithString: [NSString stringWithFormat: @"https://m.google.com/app/plus/x/?v=compose&content=%@",
                                                  [text stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ];
        [ [UIApplication sharedApplication] openURL: launchUrl ];
	}
	else if (item.shareType == SHKShareTypeText) {
        NSString *text = item.text;
        NSURL *launchUrl = [NSURL URLWithString: [NSString stringWithFormat: @"https://m.google.com/app/plus/x/?v=compose&content=%@",
                                                  [text stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ] ];
        [ [UIApplication sharedApplication] openURL: launchUrl ];
	}
    
    [self sendDidFinish];
    
	return YES;
}

@end

