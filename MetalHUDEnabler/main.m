//
//  main.m
//  MetalHUDEnabler
//
//  Created by Trevor Schmitt on 11/15/22.
//

#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import <spawn.h>

extern char **environ;
struct stat st = {0};

NSString *getBundleIdentifier(const char *applicationPath) {
    NSString *pathAsNSString = [NSString stringWithUTF8String:applicationPath];
    NSString *infoPlistPath = [pathAsNSString stringByAppendingString:@"/Contents/Info.plist"];
    if (stat([infoPlistPath UTF8String], &st)) {
        printf("Info.plist not found for %s, aborting.\n", [pathAsNSString UTF8String]);
        exit(1);
    }
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *bundleIdentifier = [infoPlist objectForKey:@"CFBundleIdentifier"];
    return bundleIdentifier;
}

void enableMetalHUD(NSString *bundleIdentifier) {
    NSString *defaultsCommand = [NSString stringWithFormat:@"defaults write %@ MetalForceHudEnabled -bool true", bundleIdentifier];
    pid_t pid;
    int status;
    const char *args[] = {"sh", "-c", [defaultsCommand UTF8String], NULL};
    posix_spawn(&pid, "/bin/sh", NULL, NULL, (char *const *)args, environ);
    waitpid(pid, &status, 0);
    printf("Metal HUD should be enabled for %s\n", [bundleIdentifier UTF8String]);
}

void disableMetalHUD(NSString *bundleIdentifier) {
    NSString *defaultsCommand = [NSString stringWithFormat:@"defaults delete %@ MetalForceHudEnabled", bundleIdentifier];
    pid_t pid;
    int status;
    const char *args[] = {"sh", "-c", [defaultsCommand UTF8String], NULL};
    posix_spawn(&pid, "/bin/sh", NULL, NULL, (char *const *)args, environ);
    waitpid(pid, &status, 0);
    printf("Metal HUD should be disabled for %s\n", [bundleIdentifier UTF8String]);
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
        NSString *bundleIdentifier = getBundleIdentifier(argv[1]);
        if (!strcmp(argv[2], "enable")) {
            enableMetalHUD(bundleIdentifier);
        }
        else if (!strcmp(argv[2], "disable")) {
            disableMetalHUD(bundleIdentifier);
        }
        else {
            printf("Unknown argument\n");
            printUsage();
            return 1;
        }
    }
    return 0;
}
