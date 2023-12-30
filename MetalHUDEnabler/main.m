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
    NSString *defaultsCommand = [NSString stringWithFormat:@"defaults write \"%@\" MetalForceHudEnabled -bool true", bundleIdentifier];
    pid_t pid;
    int status;
    const char *args[] = {"sh", "-c", [defaultsCommand UTF8String], NULL};
    posix_spawn(&pid, "/bin/sh", NULL, NULL, (char *const *)args, environ);
    waitpid(pid, &status, 0);
    printf("Metal HUD should be enabled for %s\n", [bundleIdentifier UTF8String]);
}

void disableMetalHUD(NSString *bundleIdentifier) {
    NSString *defaultsCommand = [NSString stringWithFormat:@"defaults delete \"%@\" MetalForceHudEnabled", bundleIdentifier];
    pid_t pid;
    int status;
    const char *args[] = {"sh", "-c", [defaultsCommand UTF8String], NULL};
    posix_spawn(&pid, "/bin/sh", NULL, NULL, (char *const *)args, environ);
    waitpid(pid, &status, 0);
    printf("Metal HUD should be disabled for %s\n", [bundleIdentifier UTF8String]);
}

void cxMethod(const char *flag) {
    NSString *bottlesPath = nil;
    // check if ~/CXPBottles/ exists
    if (!stat([[NSHomeDirectory() stringByAppendingString:@"/CXPBottles/"] UTF8String], &st)) {
        // ask if user wants to use ~/CXPBottles/
        printf("CXPatcher bottles directory found, use it? (yY/nN): ");
        char answer;
        scanf("%c", &answer);
        if (answer == 'n' || answer == 'N') {
            bottlesPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/CrossOver/Bottles/"];
        }
        else if (answer == 'y' || answer == 'Y') {
            bottlesPath = [NSHomeDirectory() stringByAppendingString:@"/CXPBottles/"];
        }
        else {
            printf("Invalid answer, aborting.\n");
            exit(1);
        }
    }
    else {
        bottlesPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/CrossOver/Bottles/"];
    }
    // NSArray of bottles
    NSArray *bottles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bottlesPath error:nil];
    if ([bottles count] == 0) {
        printf("No bottles found, aborting.\n");
        exit(1);
    }
    // print a list of bottles for the user to choose from
    for (int i = 0; i < [bottles count]; i++) {
        printf("%d: %s\n", i, [[bottles objectAtIndex:i] UTF8String]);
    }
    // get user input
    printf("Select the number of the CrossOver bottle: ");
    int bottleNumber;
    scanf("%d", &bottleNumber);
    NSString *cxbottlePath = [bottlesPath stringByAppendingString:[bottles objectAtIndex:bottleNumber]];
    NSString *cxbottleConfPath = [cxbottlePath stringByAppendingString:@"/cxbottle.conf"];
    NSString *cxbottleConfContents = [NSString stringWithContentsOfFile:cxbottleConfPath encoding:NSUTF8StringEncoding error:nil];
    if (!strcmp(flag, "enable")) {
        // add "MTL_HUD_ENABLED" = "1" to bottle's cxbottle.conf
        if ([cxbottleConfContents containsString:@"\n\"MTL_HUD_ENABLED\" = \"1\""]) {
            printf("Metal HUD is already enabled for the following CrossOver bottle: %s\n", [[bottles objectAtIndex:bottleNumber] UTF8String]);
            return;
        }
        cxbottleConfContents = [cxbottleConfContents stringByAppendingString:@"\n\"MTL_HUD_ENABLED\" = \"1\""];
        [cxbottleConfContents writeToFile:cxbottleConfPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        printf("Metal HUD should be enabled for the following CrossOver bottle: %s\n", [[bottles objectAtIndex:bottleNumber] UTF8String]);
    }
    else if (!strcmp(flag, "disable")) {
        // remove "MTL_HUD_ENABLED" = "1" from bottle's cxbottle.conf
        if (![cxbottleConfContents containsString:@"\n\"MTL_HUD_ENABLED\" = \"1\""]) {
            printf("Metal HUD is already disabled for the following CrossOver bottle: %s\n", [[bottles objectAtIndex:bottleNumber] UTF8String]);
            return;
        }
        cxbottleConfContents = [cxbottleConfContents stringByReplacingOccurrencesOfString:@"\n\"MTL_HUD_ENABLED\" = \"1\"" withString:@""];
        [cxbottleConfContents writeToFile:cxbottleConfPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        printf("Metal HUD should be disabled for the following CrossOver bottle: %s\n", [[bottles objectAtIndex:bottleNumber] UTF8String]);
    }
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
            if ([bundleIdentifier isEqualToString:@"com.codeweavers.CrossOver"]) {
                cxMethod("enable");
            }
            else {
                enableMetalHUD(bundleIdentifier);
            }
        }
        else if (!strcmp(argv[2], "disable")) {
            if ([bundleIdentifier isEqualToString:@"com.codeweavers.CrossOver"]) {
                cxMethod("disable");
            }
            else {
                disableMetalHUD(bundleIdentifier);
            }
        }
        else {
            printf("Unknown argument\n");
            printUsage();
            return 1;
        }
    }
    return 0;
}
