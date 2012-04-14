#include <substrate.h>


extern "C" NSArray* AFPreferencesSupportedLanguages();
static NSArray* (*original_AFPreferencesSupportedLanguages)();
static NSArray* replaced_AFPreferencesSupportedLanguages()
{
    NSArray* orig = original_AFPreferencesSupportedLanguages();
    NSMutableArray* repl = [NSMutableArray arrayWithArray:orig];
    [repl addObject:@"ja-JP"];

    return repl;
}


__attribute__((constructor)) void Init()
{
    MSHookFunction(AFPreferencesSupportedLanguages, replaced_AFPreferencesSupportedLanguages, &original_AFPreferencesSupportedLanguages);
}
