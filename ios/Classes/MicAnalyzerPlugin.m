#import "MicAnalyzerPlugin.h"
#if __has_include(<mic_analyzer/mic_analyzer-Swift.h>)
#import <mic_analyzer/mic_analyzer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mic_analyzer-Swift.h"
#endif

@implementation MicAnalyzerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMicAnalyzerPlugin registerWithRegistrar:registrar];
}
@end
