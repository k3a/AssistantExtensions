/*
 *  shared.h
 *  AssistantExtensions
 *
 *  Created by K3A on 13.3.11.
 *  Copyright 2011 K3A. All rights reserved.
 *
 */
#pragma once
#import <Foundation/Foundation.h>



void LogInfo(const char* function, const char* desc, ...);
void FlushLog();
#define Info(desc, ...) LogInfo("", desc, ##__VA_ARGS__)

NSString* getAppIdentifier();
BOOL IsPointerAnObject(const void *testPointer);
NSString* RandomUUID();
unsigned GetTimestampMsec();

void IPCCall(NSString* center, NSString* message, NSDictionary* object);
NSDictionary* IPCCallResponse(NSString* center, NSString* message, NSDictionary* object);


//#warning TODO: PT DENY ATTACH!!!
// Apple PT_DENY_ATTACH addition to disallow gdb attachment
#import <dlfcn.h>
#import <sys/types.h>

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);
#if !defined(PT_DENY_ATTACH)
# define PT_DENY_ATTACH 31
#endif  // !defined(PT_DENY_ATTACH)