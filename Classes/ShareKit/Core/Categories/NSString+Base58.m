//
//  NSString+Base54.m
//  ShareKit
//
//  Created by Water Lou on 13/05/2011.
//  Copyright 2011 First Water Tech Ltd. All rights reserved.
//

#import "NSString+Base58.h"


@implementation NSString(Base58)

+(NSString*) base58_Encode: (long long) num {
	static NSString *base58String = @"123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
	int base_count = base58String.length;
	NSMutableString *encoded = [NSMutableString stringWithCapacity:16];
	while (num >= base_count) {
		long long mod = num % base_count;
		[encoded insertString:[base58String substringWithRange:NSMakeRange(mod, 1)] atIndex:0];
		num = num / base_count;
	}
	if (num) 
		[encoded insertString:[base58String substringWithRange:NSMakeRange(num, 1)] atIndex:0];
	return encoded;
}

@end
