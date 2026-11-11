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
static BOOL RO23ReadBool(id d,NSString *name,BOOL *out) {
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
    BOOL hp=Integer(d,@"collectionType",&collection),hu=RO23ReadBool(d,@"isUltra",&ultra);
    id brand=ObjectValue(d,@"deviceBrand");
    [log addObject:[NSString stringWithFormat:@"sizeClass=%@",Fmt(hs,size)]];
    [log addObject:[NSString stringWithFormat:@"deviceCategory=%@",Fmt(hc,cat)]];
    [log addObject:[NSString stringWithFormat:@"collectionType=%@",Fmt(hp,collection)]];
    [log addObject:[NSString stringWithFormat:@"deviceBrand=%@",brand?:@"unavailable"]];
    [log addObject:[NSString stringWithFormat:@"isUltra=%@",hu?(ultra?@"true":@"false"):@"unavailable"]];
    if (RO23ReadBool(d,@"supportsFall2025FacesCapability",&fall))
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
    BOOL hb=RO23ReadBool(d,@"isZeusBlack",&black);
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

// V16: minimal read-only check of NanoTimeKit's internal-build precondition.
// Matching offline 23U95 code: NTKInternalBuild at VM 0x54601310 branches to
// the same target used by NTKShowHardwareSpecificFaces at VM 0x546014EC.
// A false result forces hardware-specific faces false before CFPreferences.
// Do not change preferences, entitlements, protected caches, or watch faces.
static void *RO23NanoTimeKitSymbol(const char *name) {
    void *symbol = dlsym(RTLD_DEFAULT, name);
    if (symbol) return symbol;
    void *handle = dlopen("/System/Library/PrivateFrameworks/NanoTimeKit.framework/NanoTimeKit",
                          RTLD_LAZY | RTLD_LOCAL);
    return handle ? dlsym(handle, name) : NULL;
}

NSString *RO23V16InternalBuildReport(void) {
    NSMutableArray<NSString *> *log = [NSMutableArray arrayWithObjects:
        @"RO23 V16 — NanoTimeKit internal-build gate (read only)",
        [NSString stringWithFormat:@"Build=%@", Build()], nil];
    if (!RO23IsTargetBuild()) {
        [log addObject:@"Not 23U95; stopped."];
        [log addObject:@"RO23 V16 END systemWrites=NO"];
        return Done(log);
    }

    typedef bool (*RO23Predicate)(void);
    RO23Predicate internalBuild = (RO23Predicate)RO23NanoTimeKitSymbol("NTKInternalBuild");
    RO23Predicate hardware = (RO23Predicate)RO23NanoTimeKitSymbol("NTKShowHardwareSpecificFaces");
    RO23Predicate internalFaces = (RO23Predicate)RO23NanoTimeKitSymbol("NTKShowInternalFaces");

    if (!internalBuild) {
        [log addObject:@"NTKInternalBuild=unavailable (symbol not exported/resolved)"];
        [log addObject:@"Gate reason: UNDETERMINED"];
    } else {
        bool internal = internalBuild();
        [log addObject:[NSString stringWithFormat:@"NTKInternalBuild=%@", internal ? @"true" : @"false"]];
        if (!internal) {
            [log addObject:@"Static inference: internal-build early return prevents the hardware-face setting check."];
        } else {
            [log addObject:@"Static inference: internal-build gate passed; hardware-face setting/cached state is next."];
        }
    }

    if (hardware)
        [log addObject:[NSString stringWithFormat:@"NTKShowHardwareSpecificFaces=%@",
                        hardware() ? @"true" : @"false"]];
    else
        [log addObject:@"NTKShowHardwareSpecificFaces=unavailable"];

    if (internalFaces)
        [log addObject:[NSString stringWithFormat:@"NTKShowInternalFaces=%@",
                        internalFaces() ? @"true" : @"false"]];
    else
        [log addObject:@"NTKShowInternalFaces=unavailable"];

    [log addObject:@"No preferences changed; no face loaded; no protected writes."];
    [log addObject:@"RO23 V16 END systemWrites=NO"];
    return Done(log);
}


// RO23 V22 — Poodle-specific in-process diagnostic.
// File identity (from the owner's real .watchface): com.apple.NTKPoodleFaceBundle.
// 23U95 Zeus implementation is NTKPoodleFace, sometimes not registered in the
// app process. A missing class here DOES NOT mean it is absent from firmware.
// No bundle injection/loading, cache writes, device changes or face installation.
NSString *RO23V22PoodleReport(void) {
    NSMutableArray<NSString *> *lines = [NSMutableArray arrayWithObjects:
        @"RO23 V22 — Hermès Circulaire / Poodle (read only)",
        [NSString stringWithFormat:@"Build=%@", Build()],
        @"ArchiveBundleID=com.apple.NTKPoodleFaceBundle (V20.1 uploaded archive)",
        nil];

    if (!RO23IsTargetBuild()) {
        [lines addObject:@"Not 23U95; target-specific evaluation stopped."];
        [lines addObject:@"RO23 V22 END systemWrites=NO"];
        return Done(lines);
    }
    id device = Device();
    if (!device) {
        [lines addObject:@"CLKDevice.currentDevice=unavailable; cannot evaluate gates."];
        [lines addObject:@"RO23 V22 END systemWrites=NO"];
        return Done(lines);
    }

    int category = 0, collection = 0;
    BOOL hasCategory = Integer(device, @"deviceCategory", &category);
    BOOL hasCollection = Integer(device, @"collectionType", &collection);
    [lines addObject:[NSString stringWithFormat:@"deviceCategory=%@", Fmt(hasCategory, category)]];
    [lines addObject:[NSString stringWithFormat:@"collectionType=%@", Fmt(hasCollection, collection)]];

    typedef bool (*RO23Predicate)(void);
    RO23Predicate internalBuild = (RO23Predicate)RO23NanoTimeKitSymbol("NTKInternalBuild");
    RO23Predicate hardwareFaces = (RO23Predicate)RO23NanoTimeKitSymbol("NTKShowHardwareSpecificFaces");
    [lines addObject:[NSString stringWithFormat:@"NTKInternalBuild=%@",
                      internalBuild ? (internalBuild() ? @"true" : @"false") : @"unavailable"]];
    BOOL canEvaluate = hardwareFaces != NULL;
    BOOL hardware = canEvaluate ? (BOOL)hardwareFaces() : NO;
    [lines addObject:[NSString stringWithFormat:@"NTKShowHardwareSpecificFaces=%@",
                      canEvaluate ? (hardware ? @"true" : @"false") : @"unavailable"]];

    if (hasCategory) {
        [lines addObject:[NSString stringWithFormat:
            @"Poodle known category==1 exclusion=%@ (other early tests unresolved)",
            category == 1 ? @"MATCH" : @"NOT MATCHED"]];
    } else {
        [lines addObject:@"Poodle known category==1 exclusion=UNDETERMINED"];
    }

    if (!hasCollection || !canEvaluate) {
        [lines addObject:@"Poodle known collection/hardware fallback=UNDETERMINED"];
    } else if (collection == 5) {
        [lines addObject:@"Poodle known collectionType==5 branch=not restricted there (other tests remain)"];
    } else {
        [lines addObject:[NSString stringWithFormat:
            @"Poodle known fallback if reached=%@ (static model, not direct face result)",
            hardware ? @"NOT RESTRICTED" : @"RESTRICTED"]];
    }

    // Check class registration in THIS process only. Never dlopen the Zeus
    // FaceBundle, invoke bundle loader or force migration. If the OS already
    // registered the class, its original eligibility method may be queried.
    Class faceClass = NSClassFromString(@"NTKPoodleFace");
    [lines addObject:[NSString stringWithFormat:@"NTKPoodleFace registered in this process=%@",
                      faceClass ? @"true" : @"false"]];
    SEL restrictionSelector = NSSelectorFromString(@"isRestrictedForDevice:");
    if (faceClass && [(id)faceClass respondsToSelector:restrictionSelector]) {
        BOOL actualRestricted =
            ((BOOL (*)(id, SEL, id))objc_msgSend)((id)faceClass, restrictionSelector, device);
        [lines addObject:[NSString stringWithFormat:
            @"NTKPoodleFace.isRestrictedForDevice(actual in-process)=%@",
            actualRestricted ? @"RESTRICTED" : @"NOT RESTRICTED"]];
    } else {
        [lines addObject:@"NTKPoodleFace.isRestrictedForDevice=unavailable (class/method not registered)"];
    }
    [lines addObject:@"A missing class here is not proof that firmware lacks the bundle."];
    [lines addObject:@"No face installed; no protected writes; no system settings changed."];
    [lines addObject:@"RO23 V22 END systemWrites=NO"];
    return Done(lines);
}
