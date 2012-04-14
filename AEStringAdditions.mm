//
//  AEStringAdditions.m
//  AssistantExtensions
//
//  Created by Kexik on 11/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AEStringAdditions.h"

@implementation NSString (AEAdditions)

-(NSMutableArray*) _letterPairs:(NSString*) string;
{
    int numPairs=[string length]-1;
    NSMutableArray* pairs=[NSMutableArray arrayWithCapacity:numPairs];
    
    int i=0;
    for (;i<numPairs; i++)
        [pairs addObject:[string substringWithRange:NSMakeRange(i,2)]];
    return pairs;
}

-(NSMutableArray*) _wordLetterPairs:(NSString*) string;
{
    NSMutableArray* allPairs=[NSMutableArray array];
    NSArray* words=[string componentsSeparatedByString:@" "];
    unsigned w=0;
    for (; w<[words count]; w++)
        [allPairs addObjectsFromArray:[self _letterPairs:[words objectAtIndex:w]]];
    return allPairs;
}

// K3A Note: not my code, but I don't know the author as well... google will help
-(float) similarityWithString:(NSString*) otherString;
{
    NSMutableArray* pairs1=[self _wordLetterPairs:[self uppercaseString]];
    NSMutableArray* pairs2=[otherString _wordLetterPairs:[otherString uppercaseString]];
    
    int intersection=0;
    int u=([pairs1 count]+[pairs2 count]);
    unsigned i=0;
    unsigned j;
    for (; i<[pairs1 count]; i++)
    {
        j=0;
        for (; j<[pairs2 count]; j++)
        {
            if ([[pairs1 objectAtIndex:i] compare:[pairs2 objectAtIndex:j]] == NSOrderedSame)
            {
                intersection++;
                [pairs2 removeObjectAtIndex:j];
            }
        }
    }
    return (2.0*intersection)/u;
}

-(NSString*)stringWithFirstUppercase
{
    if ([self length] == 0) 
        return [[self copy] autorelease];
    
    NSString* firstCh = [[self substringToIndex:1] uppercaseString];
    return [firstCh stringByAppendingString:[self substringFromIndex:1]];
}

-(NSString*)urlEncodedString
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
               (CFStringRef)self, NULL, CFSTR(":/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
    return [result autorelease];
}




static NSArray* soundexCharSets = nil;

- (void)		initSoundex
{
	if( soundexCharSets == nil )
	{
		NSMutableArray* cs = [NSMutableArray array];
		NSCharacterSet* charSet;
		
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"aeiouhw"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"bfpv"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"cgjkqsxz"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"dt"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"l"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"mn"];
		[cs addObject:charSet];
		charSet = [NSCharacterSet characterSetWithCharactersInString:@"r"];
		[cs addObject:charSet];
		
		soundexCharSets = [cs retain];
	}
}


- (NSString *)	stringByRemovingCharactersInSet:(NSCharacterSet*) charSet options:(unsigned) mask
{
	NSRange				range;
	NSMutableString*	newString = [NSMutableString string];
	unsigned			len = [self length];
	
	mask &= ~NSBackwardsSearch;
	range = NSMakeRange (0, len);
	while (range.length)
	{
		NSRange substringRange;
		unsigned pos = range.location;
		
		range = [self rangeOfCharacterFromSet:charSet options:mask range:range];
		if (range.location == NSNotFound)
			range = NSMakeRange (len, 0);
		
		substringRange = NSMakeRange (pos, range.location - pos);
		[newString appendString:[self substringWithRange:substringRange]];
		
		range.location += range.length;
		range.length = len - range.location;
	}
	
	return newString;
}


- (NSString *)	stringByRemovingCharactersInSet:(NSCharacterSet*) charSet
{
	return [self stringByRemovingCharactersInSet:charSet options:0];
}


- (unsigned)	soundexValueForCharacter:(unichar) aCharacter
{
	// returns the soundex mapping for the first character in the string. If the value returned is 0, the character should be discarded.
	
	unsigned		indx;
	NSCharacterSet* cs;
	
	for( indx = 0; indx < [soundexCharSets count]; ++indx )
	{
		cs = [soundexCharSets objectAtIndex:indx];
		
		if([cs characterIsMember:aCharacter])
			return indx;
	}
	
	return 0;
}


- (NSString*)	soundexString
{
	// returns the Soundex representation of the string. 
	/*
	 
	 Replace consonants with digits as follows (but do not change the first letter):
	 b, f, p, v => 1
	 c, g, j, k, q, s, x, z => 2
	 d, t => 3
	 l => 4
	 m, n => 5
	 r => 6
	 Collapse adjacent identical digits into a single digit of that value.
	 Remove all non-digits after the first letter.
	 Return the starting letter and the first three remaining digits. If needed, append zeroes to make it a letter and three digits.
	 
	 */
	
	[self initSoundex];
	
	if([self length] > 0)
	{
		NSMutableString* soundexStr = [NSMutableString string];
		
		// strip whitespace and convert to lower case
		
		NSString*	workingString = [[self lowercaseString] stringByRemovingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		unsigned	indx, soundValue, previousSoundValue = 0;
		
		// include first character
		
		[soundexStr appendString:[workingString substringToIndex:1]];
		
		// convert up to 3 more significant characters
		
		for( indx = 1; indx < [workingString length]; ++indx )
		{
			soundValue = [self soundexValueForCharacter:[workingString characterAtIndex:indx]];
			
			if( soundValue > 0 && soundValue != previousSoundValue )
				[soundexStr appendString:[NSString stringWithFormat:@"%d", soundValue]];
            
			previousSoundValue = soundValue;	
			
			// if we've got four characters, don't need to scan any more
			
			if([soundexStr length] >= 4)
				break;
		}
		
		// if < 4 characters, need to pad the string with zeroes
		
		while([soundexStr length] < 4)
			[soundexStr appendString:@"0"];
		
		//NSLog(@"soundex for '%@' = %@", self, soundexStr );
		
		return soundexStr;
	}
	else
		return @"";
}

- (BOOL)		soundsLikeString:(NSString*) aString
{
    if (![self length] || ![aString length]) return NO;
	return [[self soundexString] isEqualToString:[aString soundexString]];
}

//-------------------------------------- METAPHONE --------------------------------------------
#pragma mark - METAPHONE

- (NSString *)metaphone {
    NSString* aWord = self;
    
	NSString *code = @"";
	int term_length = [aWord length];
	if (term_length == 0) {
		return code;
	}
	
	//NSArray *vowels = [[NSArray alloc] initWithObjects:@"a",@"e",@"i",@"o",@"u",nil];
	
	aWord = [aWord lowercaseString];
	aWord = [aWord stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
	aWord = [aWord stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	
	if ([aWord length] == 0) {
		return code;
	}
	
	//NSString *firstChar = [aWord substringToIndex:1];
	NSString *aWord2 = [aWord substringToIndex:1];
	for (unsigned idx = 0; idx < [aWord length]; ++idx) {
		NSString *ch = [aWord substringWithRange:NSMakeRange(idx, 1)];
		if (![ch isEqualToString:[aWord2 substringWithRange:NSMakeRange([aWord2 length]-1, 1)]]) {
			aWord2 = [aWord2 stringByAppendingString:ch];
		}
	}
	
    /*	firstChar = [aWord2 substringToIndex:1];
     NSString *aWord3 = [aWord2 substringToIndex:1];
     for (int idx = 1; idx < [aWord2 length]; ++idx) {
     NSString *ch = [aWord2 substringWithRange:NSMakeRange(idx, 1)];
     if (![vowels containsObject:ch]) {
     aWord3 = [aWord3 stringByAppendingString:ch];
     }
     }*/
	
	aWord = aWord2;
	term_length = [aWord length];
	if (term_length == 0) {
		return code;
	}
	
	if (term_length > 1) {
		NSString *firstChars = [aWord substringToIndex:2];
		NSDictionary *translations = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"e",@"ae",
									  @"n",@"gn",
									  @"n",@"kn",
									  @"n",@"pn",
									  @"n",@"wr",
									  @"w",@"wh",nil];
		
		if ([translations objectForKey:firstChars] != nil) {
			aWord = [aWord substringFromIndex:2];
			code = [translations objectForKey:firstChars];
			term_length = [aWord length];
		}
	} else if ([aWord characterAtIndex:0] == 'x') {
		aWord = @"";
		code = @"s";
		term_length = 0;
	}
	
	NSDictionary *standardTranslations = [NSDictionary dictionaryWithObjectsAndKeys:
										  @"b",@"b",
										  @"k",@"c",
										  @"t",@"d",
										  @"k",@"g",
										  @"h",@"h",
										  @"k",@"k",
										  @"p",@"p",
										  @"k",@"q",
										  @"s",@"s",
										  @"t",@"t",
										  @"f",@"v",
										  @"w",@"w",
										  @"ks",@"x",
										  @"y",@"y",
										  @"s",@"z",
										  nil];
	int i = 0;
	while (i < term_length) {
		NSString *addChar=@"", *part_n_2=@"", *part_n_3=@"", *part_n_4=@"", *part_c_2=@"", *part_c_3=@"";
		if (i < (term_length - 1)) {
			part_n_2 = [aWord substringWithRange:NSMakeRange(i, 2)];
			if (i > 0) {
				part_c_2 = [aWord substringWithRange:NSMakeRange(i-1, 2)];
				part_c_3 = [aWord substringWithRange:NSMakeRange(i-1, 3)];
			}
		}
		
		if (i < (term_length - 2)) {
			part_n_3 = [aWord substringWithRange:NSMakeRange(i, 3)];
		}
		
		if (i < (term_length - 3)) {
			part_n_4 = [aWord substringWithRange:NSMakeRange(i, 4)];
		}
		
		switch ([aWord characterAtIndex:i]) {
			case 'b':
				addChar = [standardTranslations objectForKey:@"b"];
				if (i == (term_length - 1)) {
					if (i > 0) {
						if ([aWord characterAtIndex:i-1] == 'm') {
							addChar = @"";
						}
					}
				}
				break;
			case 'c':
				addChar = [standardTranslations objectForKey:@"c"];
				if ([part_c_2 isEqualToString:@"ch"]) {
					addChar = @"x";
				} else if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"c[iey]"] evaluateWithObject:part_n_2] == YES) {
					addChar = @"s";
				}
				
				if ([part_n_3 isEqualToString:@"cia"]) {
					addChar = @"x";
				}
				
				if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"sc[iey]"] evaluateWithObject:part_c_3] == YES) {
					addChar = @"";
				}
				break;
			case 'd':
				addChar = [standardTranslations objectForKey:@"d"];
				if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"dg[iey]"] evaluateWithObject:part_n_3] == YES) {
					addChar = @"j";
				}
				break;
			case 'g':
				addChar = [standardTranslations objectForKey:@"g"];
				if ([part_n_2 isEqualToString:@"gh"]) {
					if (i == (term_length - 2)) {
						addChar = @"";
					}
				} else if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"gh[aeiouy]"] evaluateWithObject:part_n_3] == YES) {
					addChar = @"";
				} else if ([part_n_2 isEqualToString:@"gn"]) {
					addChar = @"";
				} else if ([part_n_4 isEqualToString:@"gned"]) {
					addChar = @"";
				} else if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"dg[iey]"] evaluateWithObject:part_c_3] == YES) {
					addChar = @"";
				} else if ([part_n_2 isEqualToString:@"gi"]) {
					if (![part_c_3 isEqualToString:@"ggi"]) {
						addChar = @"j";
					}
				} else if ([part_n_2 isEqualToString:@"ge"]) {
					if (![part_c_3 isEqualToString:@"gge"]) {
						addChar = @"j";
					}
				} else if ([part_n_2 isEqualToString:@"gy"]) {
					if (![part_c_3 isEqualToString:@"ggy"]) {
						addChar = @"j";
					}
				} else if ([part_n_2 isEqualToString:@"gg"]) {
					addChar = @"";
				}
				break;
			case 'h':
				addChar = [standardTranslations objectForKey:@"h"];
				if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"[aeiouy]h[^aeiouy]"] evaluateWithObject:part_c_3] == YES) {
					addChar = @"";
				} else if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"[csptg]h"] evaluateWithObject:part_c_2] == YES) {
					addChar = @"";
				}
				break;
			case 'k':
				addChar = [standardTranslations objectForKey:@"k"];
				if ([part_c_2 isEqualToString:@"ck"]) {
					addChar = @"";
				}
				break;
			case 'p':
				addChar = [standardTranslations objectForKey:@"p"];
				if ([part_n_2 isEqualToString:@"ph"]) {
					addChar = @"f";
				}
				break;
			case 'q':
				addChar = [standardTranslations objectForKey:@"q"];
				break;
			case 's':
				addChar = [standardTranslations objectForKey:@"s"];
				if ([part_n_2 isEqualToString:@"sh"]) {
					addChar = @"x";
				}
				if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"si[ao]"] evaluateWithObject:part_n_3] == YES) {
					addChar = @"x";
				}
				break;
			case 't':
				addChar = [standardTranslations objectForKey:@"t"];
				if ([part_n_2 isEqualToString:@"th"]) {
					addChar = @"0";
				}
				if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"ti[ao]"] evaluateWithObject:part_n_3] == YES) {
					addChar = @"x";
				}
				break;
			case 'v':
				addChar = [standardTranslations objectForKey:@"v"];
				break;
			case 'w':
				addChar = [standardTranslations objectForKey:@"w"];
				if ([[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"w[^aeiouy]"] evaluateWithObject:part_n_2] == YES) {
					addChar = @"";
				}
				break;
			case 'x':
				addChar = [standardTranslations objectForKey:@"x"];
				break;
			case 'y':
				addChar = [standardTranslations objectForKey:@"y"];
				break;
			case 'z':
				addChar = [standardTranslations objectForKey:@"z"];
				break;
            case 'a':
            case 'e':
            case 'i':
            case 'o':
            case 'u':
                if (i == 0) {
                    addChar = [aWord substringWithRange:NSMakeRange(i,1)];
                } else {
                    addChar = @"";
                }
                break;
			default:
				addChar = [aWord substringWithRange:NSMakeRange(i, 1)];
				break;
		}
		
		code = [code stringByAppendingString:addChar];
		i += 1;
	}
	
	return code;
}

//---------------------------------

-(BOOL)isFuzzyEqualTo:(NSString*)aStr
{
    return [self soundsLikeString:aStr];
}


@end
