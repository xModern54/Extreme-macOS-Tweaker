#import <Security/Authorization.h>
#import <stdio.h>

OSStatus EMTAuthorizationExecuteWithPrivileges(
  AuthorizationRef authorization,
  const char *pathToTool,
  char * const *arguments,
  FILE **communicationsPipe
);
