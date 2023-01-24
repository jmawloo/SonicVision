//
//  TargetPlatform.h
//  testFCRN
//
//  Created by Doron Adler on 28/07/2019.
//  Copyright © 2019 Doron Adler. All rights reserved.
//

#ifndef TargetPlatform_h
#define TargetPlatform_h

// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------
// Provide the correct #ifdef environemnt for the headers when included from an external client

#if ((defined(TARGET_OS_IOS) && (TARGET_OS_IOS == 1)))
    #if !defined(IOS_TARGET)
        #define IOS_TARGET
    #endif //IOS_TARGET
#endif

#endif /* TargetPlatform_h */
