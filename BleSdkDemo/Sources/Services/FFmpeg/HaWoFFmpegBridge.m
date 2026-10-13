#import "HaWoFFmpegBridge.h"
#import "ffmpeg.h"

@implementation HaWoFFmpegBridge

+ (int)runWithArguments:(NSArray<NSString *> *)arguments {
    int argc = (int)arguments.count;
    if (argc <= 0) {
        return 1;
    }

    char **argv = calloc((size_t)argc, sizeof(char *));
    if (!argv) {
        return 1;
    }

    for (int i = 0; i < argc; i++) {
        argv[i] = strdup(arguments[i].UTF8String ?: "");
    }

    int code = ffmpeg_main(argc, argv);

    for (int i = 0; i < argc; i++) {
        free(argv[i]);
    }
    free(argv);
    return code;
}

@end
