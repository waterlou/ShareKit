/*
 * Copyright 2009 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

#import <UIKit/UIKit.h>

@protocol SHKFBLikeDialogDelegate;

@interface SHKFBLikeDialog : UIView <UIWebViewDelegate> {
  id<SHKFBLikeDialogDelegate> _delegate;
  NSURL* _loadingURL;
  UIWebView* _webView;
  UIActivityIndicatorView* _spinner;
  UIImageView* _iconView;
  UILabel* _titleLabel;
  UIButton* _closeButton;
  UIDeviceOrientation _orientation;
  BOOL _showingKeyboard;
	BOOL willHandleOrientationChanged;
	
	// title color
	CGFloat titleColor[4];
}

/**
 * The delegate.
 */
@property(nonatomic,assign) id<SHKFBLikeDialogDelegate> delegate;

/**
 * The title that is shown in the header atop the view;
 */
@property(nonatomic,copy) NSString* title;
@property (nonatomic, readonly) UIWebView *webView;	// webview inside
@property (nonatomic) BOOL willHandleOrientationChanged;

/**
 * Creates the view but does not display it.
 */
- (id)init;

/**
 * Displays the view with an animation.
 *
 * The view will be added to the top of the current key window.
 */
- (void)show;

/**
 * Displays the first page of the dialog.
 *
 * Do not ever call this directly.  It is intended to be overriden by subclasses.
 */
- (void)load;

- (void)updateWebOrientation;	// rotation webView according to current orientation

/**
 * Hides the view and notifies delegates of success or cancellation.
 */
- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated;

/**
 * Hides the view and notifies delegates of an error.
 */
- (void)dismissWithError:(NSError*)error animated:(BOOL)animated;

/**
 * Subclasses may override to perform actions just prior to showing the dialog.
 */
- (void)dialogWillAppear;

/**
 * Subclasses may override to perform actions just after the dialog is hidden.
 */
- (void)dialogWillDisappear;

/**
 * Subclasses should override to process data returned from the server in a 'fbconnect' url.
 *
 * Implementations must call dismissWithSuccess:YES at some point to hide the dialog.
 */
- (void)dialogDidSucceed:(NSURL*)url;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@protocol SHKFBLikeDialogDelegate <NSObject>

@optional

/**
 * Called when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidSucceed:(SHKFBLikeDialog*)dialog;

/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
- (void)dialogDidCancel:(SHKFBLikeDialog*)dialog;

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(SHKFBLikeDialog*)dialog didFailWithError:(NSError*)error;

/**
 * Asks if a link touched by a user should be opened in an external browser.
 *
 * If a user touches a link, the default behavior is to open the link in the Safari browser, 
 * which will cause your app to quit.  You may want to prevent this from happening, open the link
 * in your own internal browser, or perhaps warn the user that they are about to leave your app.
 * If so, implement this method on your delegate and return NO.  If you warn the user, you
 * should hold onto the URL and once you have received their acknowledgement open the URL yourself
 * using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(SHKFBLikeDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url;

@end
