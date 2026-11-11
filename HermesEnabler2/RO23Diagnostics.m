// RO23 research diagnostics (Watch6,18 / 23U95), © 2026 ZhuoXuan-MY.
// Independent extension of HermesEnabler 2 by Jinwoo Kim (@pookjw).
// Read-only: no MobileGestalt writes, cache rebuild, face installation, respring.
#import "RO23Diagnostics.h"
#import "BQCore.h"
#import <objc/message.h>
#import <dlfcn.h>
#import <sys/sysctl.h>
#import <stdint.h>
#import <stdbool.h>

static NSString *Build(void) {
    char buffer[128]={0}; size_t n=sizeof(buffer);
    if (sysctlbyname("kern.osversion",buffer,&n,NULL,0)!=0) return @"unavailable";
    return [NSString stringWithUTF8String:buffer] ?: @"unavailable";
}
BOOL RO23IsTargetBuild(void) { return [Build() isEqualToString:@"23U95"]; }
static NSString *Done(NSMutableArray<NSString *> *lines) {
    NSString *result=[lines componentsJoinedByString:@"\n"];
    BQLog(@"RO23 %@",result);  // App-owned Documents only.
    return result;
}
static id Device(void) {
    Class cls=NSClassFromString(@"CLKDevice");
    if (!cls) {
        (void)dlopen("/System/Library/Frameworks/ClockKit.framework/ClockKit",RTLD_LAZY|RTLD_LOCAL);
        cls=NSClassFromString(@"CLKDevice");
    }
    SEL sel=NSSelectorFromString(@"currentDevice");
    if (!cls || ![(id)cls respondsToSelector:sel]) return nil;
    return ((id(*)(id,SEL))objc_msgSend)((id)cls,sel);
}
static BOOL Integer(id d,NSString *name,int *out) {
    SEL sel=NSSelectorFromString(name);
    if (![d respondsToSelector:sel]) return NO;
    *out=((int(*)(id,SEL))objc_msgSend)(d,sel);
    return YES;
}
static BOOL Boolean(id d,NSString *name,BOOL *out) {
    SEL sel=NSSelectorFromString(name);
    if (![d respondsToSelector:sel]) return NO;
    *out=((BOOL(*)(id,SEL))objc_msgSend)(d,sel);
    return YES;
}
static id ObjectValue(id d,NSString *name) {
    SEL sel=NSSelectorFromString(name);
    if (![d respondsToSelector:sel]) return nil;
    // deviceBrand is an Objective-C object on 23U95, never cast to int.
    return ((id(*)(id,SEL))objc_msgSend)(d,sel);
}
static NSString *Fmt(BOOL present,int value) {
    return present ? [NSString stringWithFormat:@"%d",value] : @"unavailable";
}
NSString *RO23CacheSnapshot(void) {
    NSMutableArray<NSString *> *log=[NSMutableArray arrayWithObjects:
      @"RO23 MG cache — read only",[NSString stringWithFormat:@"Build=%@",Build()],nil];
    if (!RO23IsTargetBuild()) {
        [log addObject:@"Not 23U95; stopped."];return Done(log);
    }
    NSString *path=@"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist";
    NSData *data=[NSData dataWithContentsOfFile:path];
    if (!data) {
        [log addObject:@"Cache read denied/unavailable; no write attempted."];return Done(log);
    }
    NSError *error=nil;
    id obj=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        [log addObject:[NSString stringWithFormat:@"Invalid plist: %@",error.localizedDescription?:@"unknown"]];
        return Done(log);
    }
    NSDictionary *plist=(NSDictionary *)obj;
    id cache=plist[@"CacheData"];
    [log addObject:[NSString stringWithFormat:@"PlistBytes=%lu",(unsigned long)data.length]];
    [log addObject:[NSString stringWithFormat:@"CacheUUID=%@",plist[@"CacheUUID"]?:@"missing"]];
    [log addObject:[NSString stringWithFormat:@"CacheDataBytes=%lu",(unsigned long)[cache length]]];
    if ([cache isKindOfClass:[NSData class]] && [cache length]==0x18a5) {
        const uint8_t *b=[(NSData *)cache bytes];
        uint32_t brand=(uint32_t)b[0x338] | ((uint32_t)b[0x339]<<8) |
           ((uint32_t)b[0x33a]<<16) | ((uint32_t)b[0x33b]<<24);
        [log addObject:[NSString stringWithFormat:@"DeviceBrand index103=%u validity=%u",brand,b[0x164f]]];
    } else [log addObject:@"Cache layout mismatch; no slot decoded."];
    [log addObject:@"RO23 CACHE END systemWrites=NO"];
    return Done(log);
}
NSString *RO23ClockKitReport(void) {
    NSMutableArray<NSString *> *log=[NSMutableArray arrayWithObjects:
      @"RO23 V13 — ClockKit eligibility (read only)",[NSString stringWithFormat:@"Build=%@",Build()],nil];
    if (!RO23IsTargetBuild()) {
        [log addObject:@"Not 23U95; stopped."];return Done(log);
    }
    id d=Device();
    if (!d) {[log addObject:@"CLKDevice.currentDevice unavailable"];return Done(log);}
    int size=0,cat=0,collection=0; BOOL ultra=NO,fall=NO;
    BOOL hs=Integer(d,@"sizeClass",&size),hc=Integer(d,@"deviceCategory",&cat);
    BOOL hp=Integer(d,@"collectionType",&collection),hu=Boolean(d,@"isUltra",&ultra);
    id brand=ObjectValue(d,@"deviceBrand");
    [log addObject:[NSString stringWithFormat:@"sizeClass=%@",Fmt(hs,size)]];
    [log addObject:[NSString stringWithFormat:@"deviceCategory=%@",Fmt(hc,cat)]];
    [log addObject:[NSString stringWithFormat:@"collectionType=%@",Fmt(hp,collection)]];
    [log addObject:[NSString stringWithFormat:@"deviceBrand=%@",brand?:@"unavailable"]];
    [log addObject:[NSString stringWithFormat:@"isUltra=%@",hu?(ultra?@"true":@"false"):@"unavailable"]];
    if (Boolean(d,@"supportsFall2025FacesCapability",&fall))
        [log addObject:[NSString stringWithFormat:@"supportsFall2025FacesCapability=%@",fall?@"true":@"false"]];
    else
        [log addObject:@"supportsFall2025FacesCapability=not registered in this process"];
    if (hc) {
        BOOL allowed=cat==2||cat==3||cat==5;
        [log addObject:[NSString stringWithFormat:@"Hermes2025 category {2,3,5}: %@",allowed?@"PASS (other gates remain)":@"FAIL"]];
    }
    [log addObject:@"Static model only; no face bundle loaded."];
    [log addObject:@"RO23 V13 END systemWrites=NO"];
    return Done(log);
}
NSString *RO23ZeusReport(void) {
    NSMutableArray<NSString *> *log=[NSMutableArray arrayWithObjects:
      @"RO23 V14.1 — Zeus eligibility (read only)",[NSString stringWithFormat:@"Build=%@",Build()],nil];
    if (!RO23IsTargetBuild()) {
        [log addObject:@"Not 23U95; stopped."];return Done(log);
    }
    id d=Device();
    if (!d) {[log addObject:@"CLKDevice.currentDevice unavailable"];return Done(log);}
    int cat=0,collection=0; BOOL black=NO;
    BOOL hc=Integer(d,@"deviceCategory",&cat),hp=Integer(d,@"collectionType",&collection);
    BOOL hb=Boolean(d,@"isZeusBlack",&black);
    id brand=ObjectValue(d,@"deviceBrand");
    [log addObject:[NSString stringWithFormat:@"deviceCategory=%@",Fmt(hc,cat)]];
    [log addObject:[NSString stringWithFormat:@"collectionType=%@",Fmt(hp,collection)]];
    [log addObject:[NSString stringWithFormat:@"deviceBrand=%@",brand?:@"unavailable"]];
    [log addObject:[NSString stringWithFormat:@"deviceBrandReturnType=%@",brand?NSStringFromClass([brand class]):@"nil/unavailable"]];
    [log addObject:[NSString stringWithFormat:@"isZeusBlack=%@",hb?(black?@"true":@"false"):@"unavailable"]];
    typedef bool (*Predicate)(void);
    Predicate show=(Predicate)dlsym(RTLD_DEFAULT,"NTKShowHardwareSpecificFaces");
    if (!show) {
        void *h=dlopen("/System/Library/PrivateFrameworks/NanoTimeKit.framework/NanoTimeKit",RTLD_LAZY|RTLD_LOCAL);
        if (h) show=(Predicate)dlsym(h,"NTKShowHardwareSpecificFaces");
    }
    BOOL valid=show!=NULL;
    BOOL flag=valid ? show() : NO;
    [log addObject:[NSString stringWithFormat:@"NTKShowHardwareSpecificFaces=%@",valid?(flag?@"true":@"false"):@"unavailable"]];
    if (hp && valid) {
        BOOL restricted=collection!=5 && !flag;
        [log addObject:[NSString stringWithFormat:@"ZeusAnalog gate: %@",restricted?@"RESTRICTED":@"PASS (other gates remain)"]];
    } else [log addObject:@"ZeusAnalog gate: UNDETERMINED"];
    if (hc && hb && valid) {
        BOOL restricted=(!black||cat==1)&&!flag;
        [log addObject:[NSString stringWithFormat:@"SpectrumZeus gate: %@",restricted?@"RESTRICTED":@"PASS (other gates remain)"]];
    } else [log addObject:@"SpectrumZeus gate: UNDETERMINED"];
    if (hc) {
        BOOL restricted=cat==1||cat==4||cat==6;
        [log addObject:[NSString stringWithFormat:@"Hades/Secretariat category: %@",restricted?@"RESTRICTED":@"not rejected at first check"]];
    }
    [log addObject:@"No face installed; no protected writes."];
    [log addObject:@"RO23 V14.1 END systemWrites=NO"];
    return Done(log);
}
