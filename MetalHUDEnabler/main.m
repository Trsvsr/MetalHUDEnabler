//
//  main.m
//  MetalHUDEnabler
//
//  Created by Trevor Schmitt on 11/15/22.
//

#import <Foundation/Foundation.h>
#import <sys/stat.h>

struct stat st = {0};

NSString* getExecutablePath(const char *applicationPath) {
    NSString *pathAsNSString = [NSString stringWithUTF8String:applicationPath];
    NSString *infoPlistPath = [pathAsNSString stringByAppendingString:@"/Contents/Info.plist"];
    if (stat([infoPlistPath UTF8String], &st)) {
        printf("Info.plist not found for %s, aborting.\n", [pathAsNSString UTF8String]);
        exit(1);
    }
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *exec = [infoPlist objectForKey:@"CFBundleExecutable"];
    NSString *fullExecPath = [[pathAsNSString stringByAppendingString:@"/Contents/MacOS/"] stringByAppendingString:exec];
    return fullExecPath;
}

void enableMetalHUD(NSString *execPath) {
    NSString *newExecPath = [execPath stringByAppendingString:@"_"];
    if (stat([newExecPath UTF8String], &st)) {
        printf("Renaming executable to %s\n", [newExecPath UTF8String]);
        if (rename([execPath UTF8String], [newExecPath UTF8String])) {
            printf("Failed to rename executable, aborting.\n");
            exit(1);
        }
    }
    FILE *file = fopen([execPath UTF8String], "w");
    fprintf(file, "#!/bin/sh\nMTL_HUD_ENABLED=1 \"%s\"\n", [newExecPath UTF8String]);
    fclose(file);
    char* mode = "0755";
    int octalMode = (int)strtol(mode, 0, 8);
    chmod([execPath UTF8String], octalMode);
    printf("Metal HUD should be enabled for %s\n", [execPath UTF8String]);
}

void disableMetalHUD(NSString *execPath) {
    NSString *newExecPath = [execPath stringByAppendingString:@"_"];
    if (stat([newExecPath UTF8String], &st)) {
        printf("Executable not found, aborting.\n");
        exit(1);
    }
    if (rename([newExecPath UTF8String], [execPath UTF8String])) {
        printf("Failed to rename executable, aborting.\n");
        exit(1);
    }
    printf("Metal HUD should be disabled for %s\n", [execPath UTF8String]);
}

void printUsage() {
    printf("Usage: MetalHUDEnabler [path to application] [enable/disable]\n");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc > 3) {
            printf("Too many arguments\n");
            printUsage();
            return 1;
        }
        else if (argc < 3) {
            printf("Too few arguments\n");
            printUsage();
            return 1;
        }
        if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")) {
            printUsage();
            return 0;
        }
        NSString *execPath = getExecutablePath(argv[1]);
        if (!strcmp(argv[2], "enable")) {
            enableMetalHUD(execPath);
        }
        else if (!strcmp(argv[2], "disable")) {
            disableMetalHUD(execPath);
        }
        else {
            printf("Unknown argument\n");
            printUsage();
            return 1;
        }
    }
    return 0;
}
