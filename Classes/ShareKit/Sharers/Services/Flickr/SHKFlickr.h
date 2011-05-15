//
//  SHKTwitter.h
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

#import <Foundation/Foundation.h>
#import "SHKOAuthSharer.h"
#import "SHKTwitterForm.h"
#import "ObjectiveFlickr.h"
#import "SHKFlickrRequestDialog.h"

@interface SHKFlickr : SHKSharer <SHKFlickrRequestDialogControllerDelegate>
{	
	// context of Flickr
    OFFlickrAPIContext *flickrContext;	
	// requestDialog handle, also show get the FLickrRequest inside
	SHKFlickrRequestDialog *requestDialog;
	
	NSString *flickrLink;	// shorten result link
	NSString *tags;	// optional tags
	int privacy;	// privacy flag
}

@property (nonatomic, copy) NSString *flickrLink;
@property (nonatomic, copy) NSString *tags;
@property (nonatomic) int privacy;


#pragma mark -
#pragma mark UI Implementation


#pragma mark -
#pragma mark Share API Methods

@end
