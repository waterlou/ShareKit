#import "SHK.h"
#import "SHKFlickrRequestDialog.h"

// preferably, the auth token is stored in the keychain, but since working with keychain is a pain, we use the simpler default system
static NSString *kStoredAuthTokenKeyName = @"FlickrAuthToken";
static NSString *kGetAuthTokenStep = @"kGetAuthTokenStep";
static NSString *kCheckTokenStep = @"kCheckTokenStep";

@implementation SHKFlickrRequestDialog

@synthesize flickrContext;
@synthesize flickrRequest;

@synthesize delegate;

- (id)init {
	if (self = [super init]) {
		UIImage* iconImage = [UIImage imageNamed:@"SocialMedia.bundle/flickr/twicon.png"];
		_iconView = [[UIImageView alloc] initWithImage:iconImage];
		[self addSubview:_iconView];
		// set title
		_titleLabel.text = SHKLocalizedString(@"Connect to Flickr");	
		// set title color
		titleColor[0] = 1.0; titleColor[1] = 0; titleColor[2] = 132.0/255.0; titleColor[3] = 1.0;
	}
	return self;
}

-(void) dealloc {
	[flickrContext release];
	[super dealloc];
}

#pragma mark webViewDelegate

// so that it will open safari instead of in the webview
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSString *query = [[request URL] query];
	NSLog(@"query = %@", query);
	if (query.length>5 && [[query substringToIndex:4] isEqualToString: @"frob"]) {	// logging in
		// frob=...
		NSString *frob = [query substringFromIndex:5];				
		self.flickrRequest.sessionInfo = kGetAuthTokenStep;
		[flickrRequest callAPIMethodWithGET:@"flickr.auth.getToken" arguments:[NSDictionary dictionaryWithObjectsAndKeys:frob, @"frob", nil]];
	}
    else {
        [_spinner startAnimating];
    }
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[_spinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)inError {
    if ([inError.domain isEqualToString:@"WebKitErrorDomain"]) {    // no need to prompt for WebKit Error, only need NSURLErrorDomain
        return;
    }
	[self dismissWithError:inError animated:YES];
}

#pragma mark flickrRequest

#pragma mark OFFlickrAPIRequest delegate methods
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
	if (inRequest.sessionInfo == kGetAuthTokenStep) {
		[self setAndStoreFlickrAuthToken:[[inResponseDictionary valueForKeyPath:@"auth.token"] textContent]];
		//self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
	}
	else if (inRequest.sessionInfo == kCheckTokenStep) {
		//self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
	}
	
	NSLog(@"flickr Login success with user %@", [inResponseDictionary valueForKeyPath:@"auth.user.username"]);
	
	[_spinner stopAnimating];
	[self dismissWithSuccess:YES animated:YES];
	if (delegate && [delegate respondsToSelector:@selector(flickrAuthorize:didComplete:)]) {
		[delegate flickrAuthorize:self didComplete:flickrContext];
	}
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
	NSLog(@"flickr Login failed");
	if (inRequest.sessionInfo == kGetAuthTokenStep) {
	}
	else if (inRequest.sessionInfo == kCheckTokenStep) {
		[self setAndStoreFlickrAuthToken:nil];
	}
	
	[_spinner stopAnimating];

	[self dismissWithError:inError animated:YES];

	if (delegate && [delegate respondsToSelector:@selector(flickrAuthorize:didFailWithError:)]) {
		[delegate flickrAuthorize:self didFailWithError:inError];
	}
}

#pragma mark acessor

- (OFFlickrAPIRequest *)flickrRequest {
	if (!flickrRequest) {
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
		flickrRequest.delegate = self;		
	}
	
	return flickrRequest;
}

#pragma mark -

- (void)setAndStoreFlickrAuthToken:(NSString *)inAuthToken {
	if (![inAuthToken length]) {
		self.flickrContext.authToken = nil;
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kStoredAuthTokenKeyName];
	}
	else {
		self.flickrContext.authToken = inAuthToken;
		[[NSUserDefaults standardUserDefaults] setObject:inAuthToken forKey:kStoredAuthTokenKeyName];
	}
}

-(BOOL) login : (BOOL) promptForLogin {
	// we have auth token
	if ([self.flickrContext.authToken length]) {
		[self flickrRequest].sessionInfo = kCheckTokenStep;
		[flickrRequest callAPIMethodWithGET:@"flickr.auth.checkToken" arguments:nil];
		return YES;
	}
	if (promptForLogin) {	
		NSURL *loginURL = [self.flickrContext loginURLFromFrobDictionary:nil requestedPermission:OFFlickrWritePermission];
		NSLog(@"url = %@", [loginURL absoluteString]);
		[self.webView loadRequest:[NSURLRequest requestWithURL:loginURL]];
		[self show];
	}
	return NO;
}


@end
