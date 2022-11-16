//
//  main.m
//  MetalHUDEnabler
//
//  Created by Trevor Schmitt on 11/15/22.
//

#import <Foundation/Foundation.h>
#import <spawn.h>
#import <sys/stat.h>

struct stat st = {0};

NSString* getExecutablePath(const char *applicationPath) {
    NSString *pathAsNSString = [NSString stringWithUTF8String:applicationPath];
    NSString *infoPlistPath = [pathAsNSString stringByAppendingString:@"/Contents/Info.plist"];
    if (stat([infoPlistPath UTF8String], &st)) {
        printf("Info.plist not found for your app, aborting for now.\n");
        exit(1);
    }
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *exec = [infoPlist objectForKey:@"CFBundleExecutable"];
    NSString *fullExecPath = [[pathAsNSString stringByAppendingString:@"/Contents/MacOS/"] stringByAppendingString:exec];
    return fullExecPath;
}

void enableMetalHUD(NSString *execPath) {
    NSString *newExecPath = [execPath stringByAppendingString:@"_"];
    if (!stat([newExecPath UTF8String], &st)) {
        printf("It seems you've already enabled the Metal HUD for this application, exiting now.\n");
        exit(1);
    }
    rename([execPath UTF8String], [newExecPath UTF8String]);
    FILE *file = fopen([execPath UTF8String], "w");
    fprintf(file, "#!/bin/sh\nMTL_HUD_ENABLED=1 %s\n", [newExecPath UTF8String]);
    char* mode = "0755";
    int octalMode = (int)strtol(mode, 0, 8);
    chmod([execPath UTF8String], octalMode);
    printf("Metal HUD should be enabled for %s\n", [execPath UTF8String]);
}

void disableMetalHUD(NSString *execPath) {
    NSString *newExecPath = [execPath stringByAppendingString:@"_"];
    rename([newExecPath UTF8String], [execPath UTF8String]);
    printf("Metal HUD should be disabled for %s\n", [execPath UTF8String]);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc > 3) {
            printf("Too many arguments\n");
            return 1;
        }
        else if (argc < 3) {
            printf("Too few arguments\n");
            return 1;
        }
        if (!strcmp(argv[1], "-h") || (!strcmp(argv[1], "--help"))) {
            printf("Usage: MetalHUDEnabler [path to application] [enable/disable]\n");
            return 0;
        }
        NSString *execPath = getExecutablePath(argv[1]);
        if (!strcmp(argv[2], "enable")) {
            enableMetalHUD(execPath);
        }
        else if (!strcmp(argv[2], "disable")) {
            disableMetalHUD(execPath);
        }
    }
    return 0;
}
