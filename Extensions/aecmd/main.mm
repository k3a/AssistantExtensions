#include <AppSupport/CPDistributedMessagingCenter.h>


void IPCCall(NSString* center, NSString* message, NSDictionary* object)
{
    [[CPDistributedMessagingCenter centerNamed:center] sendMessageName:message userInfo:object];
}

int main(int argc, char **argv, char **envp) 
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	if (argc < 2)
	{
		printf("Usage: %s command [arguments]\n", argv[0]);
		printf("\nCommands:\n");
		printf(" query - shows the assistant and sends a text query\n");
		printf(" activate - activates the assistant\n");
		printf(" dismiss - dismisses the assistant\n");
		return 1;
	}

	if (!strcasecmp(argv[1], "query"))
	{
		if (argc < 3)
		{
			printf("Usage: %s query Some text request\n", argv[0]);
			[pool release];
			return 1;
		}
		
		NSMutableString* query = [NSMutableString string];
		for (int i=2; i<argc; i++) 
		{
			if (i==2)
				[query appendFormat:@"%s", argv[i]];
			else
				[query appendFormat:@" %s", argv[i]];
		}

		IPCCall(@"me.k3a.AssistantExtensions", @"ActivateAssistant", nil);
		IPCCall(@"me.k3a.AssistantExtensions", @"SubmitQuery", [NSDictionary dictionaryWithObjectsAndKeys:query,@"query",nil]);
		return 0;
	}
	else if (!strcasecmp(argv[1], "activate"))
	{
		IPCCall(@"me.k3a.AssistantExtensions", @"ActivateAssistant", nil);	
		return 0;
	}
	else if (!strcasecmp(argv[1], "dismiss"))
	{
		IPCCall(@"me.k3a.AssistantExtensions", @"DismissAssistant", nil);
		return 0;
	}

	printf("Unknown command '%s'\n", argv[1]);
	[pool release];
	return 1;
}

// vim:ft=objc
