//
//  LoadMeController.h
//  LoadMe
//
//  Created by Alex Gray on 2/6/15.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

#import <Preferences/Preferences.h>

@interface LoadMeController : PSListController
{
}

- (id)getValueForSpecifier:(PSSpecifier*)specifier;
- (void)setValue:(id)value forSpecifier:(PSSpecifier*)specifier;
- (void)followOnTwitter:(PSSpecifier*)specifier;
- (void)visitWebSite:(PSSpecifier*)specifier;
- (void)makeDonation:(PSSpecifier*)specifier;

@end