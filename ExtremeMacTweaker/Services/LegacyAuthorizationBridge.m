#import "LegacyAuthorizationBridge.h"

OSStatus EMTAuthorizationExecuteWithPrivileges(
  AuthorizationRef authorization,
  const char *pathToTool,
  char * const *arguments,
  FILE **communicationsPipe
) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  return AuthorizationExecuteWithPrivileges(
    authorization,
    pathToTool,
    kAuthorizationFlagDefaults,
    arguments,
    communicationsPipe
  );
#pragma clang diagnostic pop
}
