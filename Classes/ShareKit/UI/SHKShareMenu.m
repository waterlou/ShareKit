//
//  SHKShareMenu.m
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

#import "SHKShareMenu.h"
#import "SHK.h"
#import "SHKSharer.h"
#import "SHKCustomShareMenuCell.h"

@implementation SHKShareMenu

@synthesize item;
@synthesize tableData;
@synthesize exclusions;

#pragma mark -
#pragma mark Initialization

- (void)dealloc 
{
	[item release];
	[tableData release];
	[exclusions release];
    [super dealloc];
}


- (id)initWithStyle:(UITableViewStyle)style
{
	if (self = [super initWithStyle:style])
	{
		self.title = SHKLocalizedString(@"Share");
		
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)] autorelease];
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Edit")
																				  style:UIBarButtonItemStyleBordered
																				 target:self
																				 action:@selector(edit)] autorelease];
		
	}
	return self;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Remove the SHK view wrapper from the window
	[[SHK currentHelper] viewWasDismissed];
}


- (void)setItem:(SHKItem *)i
{
	[item release];
	item = [i retain];
	
	[self rebuildTableDataAnimated:NO];
}

- (void)rebuildTableDataAnimated:(BOOL)animated
{
	self.tableView.allowsSelectionDuringEditing = YES;
	self.tableData = [NSMutableArray arrayWithCapacity:2];
	[tableData addObject:[self section:@"actions"]];
	[tableData addObject:[self section:@"services"]];
		
	// Handling Excluded items
	// If in editing mode, show them
	// If not editing, hide them
	self.exclusions = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"SHKExcluded"] mutableCopy] autorelease];
	
	if (exclusions == nil)
		self.exclusions = [NSMutableDictionary dictionaryWithCapacity:0];
	
	NSMutableArray *excluded = [NSMutableArray arrayWithCapacity:0];
		
	if (!self.tableView.editing || animated)
	{
		int s = 0;
		int r = 0;
		
		// Use temp objects so we can mutate as we are enumerating
		NSMutableArray *sectionCopy;
		NSMutableDictionary *tableDataCopy = [[tableData mutableCopy] autorelease];
		NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
				
		for(NSMutableArray *section in tableDataCopy)
		{
			r = 0;
			[indexes removeAllIndexes];
			
			sectionCopy = [[section mutableCopy] autorelease];
			
			for (NSMutableDictionary *row in section)
			{
				if ([exclusions objectForKey:[row objectForKey:@"className"]])
				{
					[excluded addObject:[NSIndexPath indexPathForRow:r inSection:s]];
					
					if (!self.tableView.editing)
						[indexes addIndex:r];
				}
				
				r++;
			}
				
			if (!self.tableView.editing)
			{
				[sectionCopy removeObjectsAtIndexes:indexes];
				[tableData replaceObjectAtIndex:s withObject:sectionCopy];
			}
			
			s++;
		}
		
		[indexes release];
		
		if (animated)
		{
			[self.tableView beginUpdates];	
			
			if (!self.tableView.editing)
				[self.tableView deleteRowsAtIndexPaths:excluded withRowAnimation:UITableViewRowAnimationFade];		
			else
				[self.tableView insertRowsAtIndexPaths:excluded withRowAnimation:UITableViewRowAnimationFade];		
			
			[self.tableView endUpdates];
		}
	}
	
}

- (NSMutableArray *)section:(NSString *)section
{
	id class;
	NSMutableArray *sectionData = [NSMutableArray arrayWithCapacity:0];	
	NSArray *source = [[SHK sharersDictionary] objectForKey:section];
	
	for( NSString *sharerClassName in source)
	{
		class = NSClassFromString(sharerClassName);
		if ( [class canShare] && [class canShareType:item.shareType] )
			[sectionData addObject:[NSDictionary dictionaryWithObjectsAndKeys:sharerClassName,@"className",[class sharerTitle],@"name",nil]];
	}

	if (sectionData.count && SHKShareMenuAlphabeticalOrder)
		[sectionData sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease]]];
	
	return sectionData;
}

#pragma mark -
#pragma mark View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    NSInteger num_of_section = tableData.count;
#if SHKLogoutAllInMenu
    num_of_section++;
#endif
    return num_of_section;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    if (section>=tableData.count) return 1; // logout
    return [[tableData objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    if (indexPath.section>=tableData.count) {
        // logout
        static NSString *CellIdentifier = @"LogoutCell";        
        SHKCustomShareMenuCell *cell = (SHKCustomShareMenuCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[[SHKCustomShareMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.textLabel.text = SHKLocalizedString(@"Logout of All Services");
            cell.textLabel.textAlignment = UITextAlignmentCenter;
        }        
        // logout
        return cell;
    }

    static NSString *CellIdentifier = @"Cell";
    
    SHKCustomShareMenuCell *cell = (SHKCustomShareMenuCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
        cell = [[[SHKCustomShareMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

    
	NSDictionary *rowData = [self rowDataAtIndexPath:indexPath];
	cell.textLabel.text = [rowData objectForKey:@"name"];
    
    UIImage *icon = [UIImage imageNamed: [NSString stringWithFormat: @"ShareKit.bundle/%@.png", [rowData objectForKey:@"className"]]];    
    cell.imageView.image = icon;
	
	if (cell.editingAccessoryView == nil)
	{
		UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
		toggle.userInteractionEnabled = NO;
		cell.editingAccessoryView = toggle;
		[toggle release];
	}
	
	[(UISwitch *)cell.editingAccessoryView setOn:[exclusions objectForKey:[rowData objectForKey:@"className"]] == nil];
	
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (indexPath.section>=tableData.count) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        // logout all service
        [self logoutAll];
        return;
    }
    
	NSDictionary *rowData = [self rowDataAtIndexPath:indexPath];
	
	if (tableView.editing)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		
		UISwitch *toggle = (UISwitch *)[cell editingAccessoryView];
        BOOL nowOn = !toggle.on;
		[toggle setOn:nowOn animated:YES];
		
		if (nowOn)
			[exclusions removeObjectForKey:[rowData objectForKey:@"className"]];
		
		else 
			[exclusions setObject:@"1" forKey:[rowData objectForKey:@"className"]];

		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}
	
	else 
	{
		[NSClassFromString([rowData objectForKey:@"className"]) shareItem:item];
		
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	}
}

- (NSDictionary *)rowDataAtIndexPath:(NSIndexPath *)indexPath
{
	return [[tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section>=tableData.count) return nil;   // logout button
    
	if ([[tableData objectAtIndex:section] count])
	{
		if (section == 0)
			return SHKLocalizedString(@"Actions");
		
		else if (section == 1)
			return SHKLocalizedString(@"Services");
	}
	
	return nil;
}


#pragma mark -
#pragma mark Toolbar Buttons

- (void)cancel
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void)edit
{
	[self.tableView setEditing:YES animated:YES];
	[self rebuildTableDataAnimated:YES];
	
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			 target:self
																							  action:@selector(save)] autorelease] animated:YES];
}

- (void)save
{
	[[NSUserDefaults standardUserDefaults] setObject:exclusions forKey:@"SHKExcluded"];	
	
	[self.tableView setEditing:NO animated:YES];
	[self rebuildTableDataAnimated:YES];
	
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Edit")
																				 style:UIBarButtonItemStyleBordered
																							  target:self
																							  action:@selector(edit)] autorelease] animated:YES];
	
}

#pragma mark -

- (void)logoutAll
{
	[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Logout")
								 message:SHKLocalizedString(@"Are you sure you want to logout of all share services?")
								delegate:self
					   cancelButtonTitle:SHKLocalizedString(@"Cancel")
					   otherButtonTitles:SHKLocalizedString(@"Logout"),nil] autorelease] show];
	
	[SHK logoutOfAll];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
		[SHK logoutOfAll];
}

@end

