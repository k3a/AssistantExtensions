/*
 *  shared.mm
 *  AssitantExtensions
 *
 *  Created by K3A on 13.3.11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "shared.h"
#include <AppSupport/CPDistributedMessagingCenter.h>

#pragma mark - LOGGING -----------------------------------------------------------

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

void LogInfo(const char* function, const char* desc, ...)
{
	static char buffer[1024];
	
	va_list argList;
	va_start(argList, desc);
	vsprintf(buffer, desc, argList);
	va_end(argList);
	
	// get time
	time_t tim;
	time(&tim);
	tm *timm = localtime(&tim);
	int tda = timm->tm_mday;
	int tmo = timm->tm_mon+1;
	int tho = timm->tm_hour;
	int tmi = timm->tm_min;
	
	char buffer2[2048];
	sprintf(buffer2, "ObjcDump[%d.%d@%d:%d]: %d: %s\r\n", tda, tmo, tho, tmi, getpid(), buffer);
	
	//print
	//printf("%s", buffer2);
    NSLog(@"%s", buffer2);
}

void FlushLog()
{
    static volatile int i=0;
    i++;
    //fflush(fp);
}

#pragma mark - APP IDENTIFIER -----------------------------------------------------------

#include <sys/sysctl.h>

NSString* getAppIdentifier()
{
    NSString* appIdent = nil;
    if (!appIdent)
    {
        NSString *returnString = nil;
        int mib[4], maxarg = 0, numArgs = 0;
        size_t size = 0;
        char *args = NULL, *namePtr = NULL, *stringPtr = NULL;
        
        mib[0] = CTL_KERN;
        mib[1] = KERN_ARGMAX;
        
        size = sizeof(maxarg);
        if ( sysctl(mib, 2, &maxarg, &size, NULL, 0) == -1 ) {
            return @"Unknown";
        }
        
        args = (char *)malloc( maxarg );
        if ( args == NULL ) {
            return @"Unknown";
        }
        
        mib[0] = CTL_KERN;
        mib[1] = KERN_PROCARGS2;
        mib[2] = getpid();
        
        size = (size_t)maxarg;
        if ( sysctl(mib, 3, args, &size, NULL, 0) == -1 ) {
            free( args );
            return @"Unknown";
        }
        
        memcpy( &numArgs, args, sizeof(numArgs) );
        stringPtr = args + sizeof(numArgs);
        
        if ( (namePtr = strrchr(stringPtr, '/')) != NULL ) {
            namePtr++;
            returnString = [[NSString alloc] initWithUTF8String:namePtr];
        } else {
            returnString = [[NSString alloc] initWithUTF8String:stringPtr];
        }
        
        return [returnString autorelease];
    }
    
    if (!appIdent) appIdent = [[NSBundle mainBundle] bundleIdentifier];
    
    return appIdent;
}


#pragma mark - IS VALID POINTER? -----------------------------------------------------------

#import <malloc/malloc.h>
#import <objc/runtime.h>

static sigjmp_buf sigjmp_env;

inline void PointerReadFailedHandler(int signum)
{
    siglongjmp (sigjmp_env, 1);
}

BOOL IsPointerAnObject(const void *testPointer)
{
    BOOL allocatedLargeEnough = NO;
    if (!testPointer) return NO;
    
    // Set up SIGSEGV and SIGBUS handlers
    struct sigaction new_segv_action, old_segv_action;
    struct sigaction new_bus_action, old_bus_action;
    new_segv_action.sa_handler = PointerReadFailedHandler;
    new_bus_action.sa_handler = PointerReadFailedHandler;
    sigemptyset(&new_segv_action.sa_mask);
    sigemptyset(&new_bus_action.sa_mask);
    new_segv_action.sa_flags = 0;
    new_bus_action.sa_flags = 0;
    sigaction (SIGSEGV, &new_segv_action, &old_segv_action);
    sigaction (SIGBUS, &new_bus_action, &old_bus_action);
    
    // The signal handler will return us to here if a signal is raised
    if (sigsetjmp(sigjmp_env, 1))
    {
        sigaction (SIGSEGV, &old_segv_action, NULL);
        sigaction (SIGBUS, &old_bus_action, NULL);
        return NO;
    }
    
    Class testPointerClass = *((Class *)testPointer);
    
    // Get the list of classes and look for testPointerClass
    BOOL isClass = NO;
    NSInteger numClasses = objc_getClassList(NULL, 0);
    Class *classesList = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classesList, numClasses);
    for (int i = 0; i < numClasses; i++)
    {
        if (classesList[i] == testPointerClass)
        {
            isClass = YES;
            break;
        }
    }
    free(classesList);
    
    // We're done with the signal handlers (install the previous ones)
    sigaction (SIGSEGV, &old_segv_action, NULL);
    sigaction (SIGBUS, &old_bus_action, NULL);
    
    // Pointer does not point to a valid isa pointer
    if (!isClass)
    {
        return NO;
    }
    
    // Check the allocation size
    size_t allocated_size = malloc_size(testPointer);
    size_t instance_size = class_getInstanceSize(testPointerClass);
    if (allocated_size > instance_size)
    {
        allocatedLargeEnough = YES;
    }
    
    return allocatedLargeEnough;
}

#pragma mark - OTHER HELPERS -----------------------------------------------------------

NSString* RandomUUID()
{
    return [NSString stringWithFormat:@"1%07x-%04x-%04x-%04x-%06x%06x", rand()%0xFFFFFFF, rand()%0xFFFF, rand()%0xFFFF, rand()%0xFFFF, rand()%0xFFFFFF, rand()%0xFFFFFF];
}

unsigned GetTimestampMsec()
{
    timeval time;
    gettimeofday(&time, NULL);
    
    unsigned elapsed_seconds  = time.tv_sec;
    unsigned elapsed_useconds = time.tv_usec;
    
    return elapsed_seconds * 1000 + elapsed_useconds/1000;
}

void IPCCall(NSString* center, NSString* message, NSDictionary* object)
{
    [[CPDistributedMessagingCenter centerNamed:center] sendMessageName:message userInfo:object];
}

NSDictionary* IPCCallResponse(NSString* center, NSString* message, NSDictionary* object)
{
    return [[CPDistributedMessagingCenter centerNamed:center] sendMessageAndReceiveReplyName:message userInfo:object];
}











