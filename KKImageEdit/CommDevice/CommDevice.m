//
//  CommDevice.m
//
//  Created by finger on 16/7/4.
//  Copyright © 2016年 finger. All rights reserved.
//

#import "CommDevice.h"

#if (TARGET_IPHONE_SIMULATOR)
#import <net/if_types.h>
#import <net/route.h>
#import <netinet/if_ether.h>
#else
#import "if_types.h"
#import "route.h"
#import "if_ether.h"
#endif

#import <arpa/inet.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <ifaddrs.h>
#import <net/if_dl.h>
#import <net/if.h>
#import <netinet/in.h>

#import <SystemConfiguration/CaptiveNetwork.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define ROUNDUP(a) ((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

@implementation CommDevice

+ (NSString *)deviceModel
{
    return [[UIDevice currentDevice] model];
}

+ (NSString *)deviceName
{
    return [[UIDevice currentDevice] name];
}

+ (NSString *)deviceSystemVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)deviceSystemName
{
    return [[UIDevice currentDevice] systemName];
}

+ (NSString *)deviceCurrentLanguage
{
    NSArray *languages = [NSLocale preferredLanguages];
    
    NSString *curLanguage = [languages objectAtIndex:0];
    
    return curLanguage;
}

+ (int)deviceBatteryValue
{
    return [[UIDevice currentDevice] batteryLevel]*100;
}

+ (CGSize)deviceResolution
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    return CGSizeMake(screenSize.width*scale, screenSize.height*scale);
}

+ (CGFloat)deviceScreenScale
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    return scale;

}

+ (NSString *)systemVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

+ (CGFloat)IOSVersion
{
    return [[self systemVersion] floatValue];
}

+ (BOOL)IOS7
{
    float systemValue = [[self systemVersion] floatValue];

    if (systemValue >= 7.0 && systemValue < 8.0){
        return YES;
    }
    
    return NO;
}

+ (BOOL)IOS8
{
    float systemValue = [[self systemVersion] floatValue];
    
    if (systemValue >= 8.0 && systemValue < 9.0){
        return YES;
    }
    
    return NO;
}

+ (BOOL)IOS9
{
    float systemValue = [[self systemVersion] floatValue];
    
    if (systemValue >= 9.0 && systemValue < 10.0){
        return YES;
    }

    return NO;
}

+ (BOOL)IOS10
{
    float systemValue = [[self systemVersion] floatValue];
    
    if (systemValue >= 10.0 && systemValue < 11.0){
        return YES;
    }
    
    return NO;
}

+ (BOOL)IOS103
{
    float systemValue = [[self systemVersion] floatValue];
    
    if (systemValue >= 10.3){
        return YES;
    }
    
    return NO;
}

+ (DeviceType)getIPhoneType
{
    DeviceType devType = iPhoneType_6 ;
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    if((CGRectGetWidth(frame) == 320) && (CGRectGetHeight(frame) == 480)){
        devType = iPhoneType_4;
    }
    
    if ((CGRectGetWidth(frame) == 320) && (CGRectGetHeight(frame) == 568)){
        devType = iPhoneType_5;
    }
    
    if ((CGRectGetWidth(frame) == 375) && (CGRectGetHeight(frame) == 667)){
        devType = iPhoneType_6;
    }
    
    if ((CGRectGetWidth(frame) == 414) && (CGRectGetHeight(frame) == 736)){
        devType = iPhoneType_6_plus;
    }
    
    return devType;
}

+ (DeviceType)getDeviceType
{
    UIUserInterfaceIdiom interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom] ;
    
    if(interfaceIdiom == UIUserInterfaceIdiomPhone){
        return [self getIPhoneType];
    }else if(interfaceIdiom == UIUserInterfaceIdiomPad){
        return iPadType_ALL ;
    }
    
    return iPhoneType_unknow ;
}

+ (long long)deviceTotalSpace
{
    NSDictionary *deviceAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];

    return [[deviceAttributes objectForKey:NSFileSystemSize] longLongValue];
}

+ (NSString *)deviceTotalSpaceToString
{
    int multiplyFactor = 0;
    double convertedValue = [CommDevice deviceTotalSpace];
    
    NSArray *tokens = [NSArray arrayWithObjects:@"B",@"KB",@"MB",@"GB",@"TB",nil];
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.1f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

+ (long long)deviceFreeSpace
{
    NSDictionary *deviceAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];

    return [[deviceAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
}

+ (NSString *)deviceFreeSpaceToString
{
    int multiplyFactor = 0;
    double convertedValue = [CommDevice deviceFreeSpace];
    
    NSArray *tokens = [NSArray arrayWithObjects:@"B",@"KB",@"MB",@"GB",@"TB",nil];
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.1f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

+ (NSString *)description
{
    return [NSString stringWithFormat:@"Device Info :\n{\nDevice Name = %@\nDevice Model = %@\nSystem Name = %@\nSystemm Version = %@\nDevice Language = %@\n}",
            [self deviceName],
            [self deviceModel],
            [self deviceSystemName],
            [self deviceSystemVersion],
            [self deviceCurrentLanguage]];
}

#pragma mark - 手机功能

//震动
+ (void)PhoneVibration
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

//手机铃声
+ (void)PhoeTone
{
    [self PhoneToneWithType:kPhoneToneSoundID_Default soundFilePath:nil];
}

+ (void)PhoneToneWithSoundFilePath:(NSString *)filePath
{
    [self PhoneToneWithType:kPhoneToneSoundID_Custom soundFilePath:filePath];
}

+ (void)PhoneToneWithType:(PhoneToneSoundID)soundId soundFilePath:(NSString *)filePath
{
    NSString *audioPath = nil;
    
    if (soundId == kPhoneToneSoundID_Default){
        
        audioPath = [NSString stringWithFormat:@"/System/Library/Audio/UISounds/%@.%@",@"sms-received1",@"caf"];
        
    }else{
        
        //custom
        audioPath = filePath;
        if (![[NSFileManager defaultManager]fileExistsAtPath:audioPath]){
            return;
        }
    }
    
    SystemSoundID theSoundId = 0;
    
    if (audioPath){
        
        OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:audioPath], &theSoundId);
        
        if (error){
            return;
        }
        
    }
    
    if (theSoundId > 0){
        AudioServicesPlaySystemSound(theSoundId);
    }
}

#pragma mark- Open System Settings(NS_AVAILABLE_IOS(8_0))

+ (void)openSystemSettingWiFi
{
    NSURL*url=[NSURL URLWithString:@"prefs:root=WIFI"];
    [[UIApplication sharedApplication] openURL:url];
}

+ (void)openSystemSettingAppCompetence
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - 闪光灯

+ (void)turnTorchOn:(BOOL)on
{
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([captureDevice hasTorch] && [captureDevice hasFlash]){
        
        [captureDevice lockForConfiguration:nil];
        
        if (on){
            [captureDevice setTorchMode:AVCaptureTorchModeOn];
            [captureDevice setFlashMode:AVCaptureFlashModeOn];
        }else{
            [captureDevice setTorchMode:AVCaptureTorchModeOff];
            [captureDevice setFlashMode:AVCaptureFlashModeOff];
        }
        
        [captureDevice unlockForConfiguration];
    }
}

#pragma mark- 获取当前的网络类型

+ (NetworkType )getCurrentNetworkType
{
    //该方法需要保证statusbar没有隐藏.
    UIApplication *app = [UIApplication sharedApplication];
    
    NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    
    int type = 0;
    
    for (id child in children){
        
        if ([child isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]){
            
            type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
            
            break;
        }
    }
    
    return type;
}

#pragma mark - 获取当前已连接网络名称

+ (NSString *)getWifiName
{
    NSString *ssid = nil;
    NSArray *ifs = (__bridge   id)CNCopySupportedInterfaces();
    for (NSString *ifname in ifs) {
        NSDictionary *info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifname);
        if (info[@"SSID"]){
            ssid = info[@"SSID"];
        }
    }
    
    return ssid;
}

#pragma mark -- 获取设备当前ip地址

+ (void)deviceIpAddress:(void(^)(NSString *ip))resultHandler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString *ip = [CommDevice deviceIpAddress] ;
        
        if(resultHandler){
            resultHandler(ip);
        }
        
    });
}

+ (NSString *)deviceIpAddress
{
    @autoreleasepool {
        
        NSMutableDictionary* result = [NSMutableDictionary dictionary];
        
        struct ifaddrs*	addrs;
        
        BOOL success = (getifaddrs(&addrs) == 0);
        
        if (success) {
            
            const struct ifaddrs* cursor = addrs;
            
            while (cursor != NULL) {
                
                NSMutableString* ip;
                
                if (cursor->ifa_addr->sa_family == AF_INET) {
                    
                    const struct sockaddr_in* dlAddr = (const struct sockaddr_in*)cursor->ifa_addr;
                    
                    const uint8_t* base = (const uint8_t*)&dlAddr->sin_addr;
                    
                    ip = [NSMutableString new];
                    
                    for (int i = 0; i < 4; i++) {
                        
                        if (i != 0)
                            [ip appendFormat:@"."];
                        
                        [ip appendFormat:@"%d", base[i]];
                        
                    }
                    
                    [result setObject:(NSString*)ip forKey:[NSString stringWithFormat:@"%s", cursor->ifa_name]];
                    
                }
                
                cursor = cursor->ifa_next;
            }
            
            freeifaddrs(addrs);
        }
        
        if ([[result allKeys] containsObject:@"en0"]){
            
            return (NSString *)[result objectForKey:@"en0"];
            
        }
    }
    
    return nil ;
}

#pragma mark -- 获取mac地址

+ (NSString*)ipToMacAddress:(NSString*)ipAddress
{
    NSString* res = nil;
    
    in_addr_t addr = inet_addr([ipAddress UTF8String]);
    
    size_t needed;
    char *buf, *next;
    
    struct rt_msghdr *rtm;
    struct sockaddr_inarp *sin;
    struct sockaddr_dl *sdl;
    
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_LLINFO};
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0){
        return nil;
    }
    
    if ((buf = (char*)malloc(needed)) == NULL){
        return nil;
    }
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0){
        return nil;
    }
    
    for (next = buf; next < buf + needed; next += rtm->rtm_msglen){
        
        rtm = (struct rt_msghdr *)next;
        sin = (struct sockaddr_inarp *)(rtm + 1);
        sdl = (struct sockaddr_dl *)(sin + 1);
        
        if (addr != sin->sin_addr.s_addr || sdl->sdl_alen < 6)
            continue;
        
        u_char *cp = (u_char*)LLADDR(sdl);
        
        res = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
               cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]];
        
        break;
    }
    
    free(buf);
    
    return res;
}

#pragma mark -- 获取路由ip

+ (NSString*)getRouteIpAddress
{
    NSString* res = nil;
    
    size_t needed;
    char *buf, *next;
    
    struct rt_msghdr *rtm;
    struct sockaddr * sa;
    struct sockaddr * sa_tab[RTAX_MAX];
    int i = 0;
    
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_GATEWAY};
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), NULL, &needed, NULL, 0) < 0){
        return nil;
    }
    
    if ((buf = (char*)malloc(needed)) == NULL){
        return nil;
    }
    
    if (sysctl(mib, sizeof(mib) / sizeof(mib[0]), buf, &needed, NULL, 0) < 0){
        return nil;
    }
    
    for (next = buf; next < buf + needed; next += rtm->rtm_msglen){
        
        rtm = (struct rt_msghdr *)next;
        sa = (struct sockaddr *)(rtm + 1);
        
        for(i = 0; i < RTAX_MAX; i++){
            
            if(rtm->rtm_addrs & (1 << i)){
                
                sa_tab[i] = sa;
                sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
                
            }else{
                sa_tab[i] = NULL;
            }
            
        }
        
        if(((rtm->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
           && sa_tab[RTAX_DST]->sa_family == AF_INET
           && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET){
            
            if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
                
                char ifName[128];
                if_indextoname(rtm->rtm_index,ifName);
                
                if(strcmp("en0",ifName) == 0){
                    
                    struct in_addr temp;
                    temp.s_addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                    res = [NSString stringWithUTF8String:inet_ntoa(temp)];
                    
                }
            }
        }
    }
    
    free(buf);
    
    return res;
}

@end
