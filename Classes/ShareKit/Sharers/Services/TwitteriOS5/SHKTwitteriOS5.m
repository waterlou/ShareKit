//
//  SHKTwitteriOS5.m
//  ShareKit
//
//  Created by Water Lou on 24/3/12.
//  Copyright (c) 2012 First Water Tech Ltd. All rights reserved.
//

#import <Twitter/Twitter.h>
#import "SHKTwitteriOS5.h"

@interface SHKTwitteriOS5()

@property (nonatomic, retain) TWTweetComposeViewController *twController;

@end

@implementation SHKTwitteriOS5

@synthesize twController;

- (id)init
{
	if (self = [super init])
	{	
	}	
	return self;
}

- (void) dealloc {
    self.twController = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Twitter";
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

// TODO use img.ly to support this
+ (BOOL)canShareImage
{
	return YES;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {
    // Buildin twitter support will use settings for account settings, so we can't add auth form and we will report no need for authentication
    return YES;
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
    TWTweetComposeViewController *vc = [[TWTweetComposeViewController alloc] init];
	if (item.shareType == SHKShareTypeURL)
	{        
        NSString *string = item.text ? item.text : item.title;
        if (string.length>140) string = [string substringToIndex:140];
        [vc addURL: item.URL];
        [vc setInitialText: string ];
	}	
	else if (item.shareType == SHKShareTypeImage)
	{
        NSString *string = item.title;
        if (string.length>140) string = [string substringToIndex:140];
        [vc addImage: item.image];
        [vc setInitialText: string ];
	}	
	else if (item.shareType == SHKShareTypeText)
	{
        NSString *string = item.text;
        if (string.length>140) string = [string substringToIndex:140];
        [vc setInitialText: string ];
	}

    /*
     [self.twController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
     self.twController = nil; 
     }];
     */
        
    // setRootView
    // Find the top window (that is not an alert view or other window)
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    if (topWindow.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(topWindow in windows)
        {
            if (topWindow.windowLevel == UIWindowLevelNormal)
                break;
        }
    }
        
    UIView *rootView = [[topWindow subviews] objectAtIndex:0];	
    id nextResponder = [rootView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        [[SHK currentHelper] setRootViewController: nextResponder];
    
    
    UIViewController *topViewController = [[SHK currentHelper] getTopViewController];	
    [topViewController presentModalViewController:vc animated:YES];
    [vc release];
}

@end
