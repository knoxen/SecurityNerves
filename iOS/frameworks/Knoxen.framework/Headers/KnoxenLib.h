//
//  KnoxenLib.h
//  Knoxen
//
//  Created by Paul Rogers on 10/8/15.
//  © 2016-2017 Knoxen, LLC. All rights reserved.
//
//  Declartions of
//    - structs and enums
//    - lib functions
//
#ifndef KNOXEN_LIB_H
#define KNOXEN_LIB_H

#include <stdbool.h>
#include <stdlib.h>

//==============================================================================================
//
//  Basic Knoxen Types
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
//  KnString
//
//----------------------------------------------------------------------------------------------
typedef char * KnString;

//----------------------------------------------------------------------------------------------
//
//  KnData
//    - tracks the size and ownership of bytes.
//
//----------------------------------------------------------------------------------------------
typedef struct {
  unsigned char * bytes;
  size_t          size;
  bool            own;
} * KnData;

//==============================================================================================
//
//  Enums
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
//  Enum for Knoxen's two distinct client types:
//    - Lib client negotiated using the client and server libs' pre-established relationship.
//    - User client negotiated for a registered user identity.
//
//----------------------------------------------------------------------------------------------
typedef enum {
  KnLibClient     = 1,
  KnLibUserClient = 2,
  KnUserClient    = 3
} KnClientType;

//----------------------------------------------------------------------------------------------
//
//  Enum for Knoxen user identity registration
//
//----------------------------------------------------------------------------------------------
typedef enum {
  KnRegistrationNone      =   0,
  KnRegistrationCreate    =   1,
  KnRegistrationUpdate    =   2,
  KnRegistrationOk        =  10,
  KnRegistrationDuplicate =  11,
  KnRegistrationNotFound  =  12,
  KnRegistrationError     = 255
} KnRegistrationCode;

//----------------------------------------------------------------------------------------------
//
//  Enum for Knoxen user identity key negotiation
//
//----------------------------------------------------------------------------------------------
typedef enum {
  KnUserOk               =   1,
  KnUserInvalidIdentity  =   2,
  KnUserInvalidPassword  =   3,
  KnUserError            = 255
} KnUserCode;

//----------------------------------------------------------------------------------------------
//
//  Enum for Knoxen encryption originator
//
//----------------------------------------------------------------------------------------------
typedef enum {
  KnOriginRequester = 1,
  KnOriginResponder = 2
} KnOrigin;

//==============================================================================================
//
//  Private structs
//
//==============================================================================================
typedef struct KNOXEN_key_agreement_st * KnKeyAgreement;
typedef struct KNOXEN_key_st           * KnKey;
typedef struct KNOXEN_registration_st  * KnRegistration;
typedef struct KNOXEN_verifier_st      * KnVerifier;

//==============================================================================================
//
//  Public Functions
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
// Knoxen Id
//
//----------------------------------------------------------------------------------------------
const char * knId(void);

//----------------------------------------------------------------------------------------------
//
// Knoxen Option
//
//----------------------------------------------------------------------------------------------
const char * knOption(void);

//----------------------------------------------------------------------------------------------
//
//  Knoxen version. Format M.m.p, with M, m, and p integers.
//   - M : major
//   - m : minor
//   - p : patch
//
//----------------------------------------------------------------------------------------------
const char * knVersion(void);

//----------------------------------------------------------------------------------------------
//
//  Version of Crypto library
//
//----------------------------------------------------------------------------------------------
const char * knCryptoVersion(void);

//----------------------------------------------------------------------------------------------
//
//  Description of Knoxen processing error.
//
//  Returns
//   - Const string description of error when NULL is returned from function calls.
//   - NULL if no error.
//
//----------------------------------------------------------------------------------------------
const char * knError(void);

//----------------------------------------------------------------------------------------------
//
//  Random string formed from file system and URL safe base 64 characters. (Ref: RFC-4648)
//
//  Returns
//   - String of specified size.
//
//  Use knStringFree to free the KnString memory.
//
//----------------------------------------------------------------------------------------------
KnString knStringB64FsUrl(const size_t size);

//----------------------------------------------------------------------------------------------
//
//  Create an KnData using the provided bytes which are not copied. The KnData takes
//  ownership of the bytes as specified by the own parameter.
//
//  Use knDataFree to free the KnData memory.
//
//----------------------------------------------------------------------------------------------
KnData knDataBytes(unsigned char * bytes, const size_t size, const bool own);

//----------------------------------------------------------------------------------------------
//
//  Create an KnData by copying the provided bytes.
//
//  Use knDataFree to free the KnData memory.
//
//----------------------------------------------------------------------------------------------
KnData knDataBytesCopy(const unsigned char * bytes, const size_t size);

//----------------------------------------------------------------------------------------------
//
//  Size of an KnData
//
//----------------------------------------------------------------------------------------------
size_t knDataGetSize(const KnData data);

//----------------------------------------------------------------------------------------------
//
//  Pointer to KnData bytes
//
//----------------------------------------------------------------------------------------------
unsigned char * knDataGetBytes(const KnData data);

//----------------------------------------------------------------------------------------------
//
//  String id of KnKey
//
//----------------------------------------------------------------------------------------------
const KnString knKeyId(const KnKey knKey);

//----------------------------------------------------------------------------------------------
//
//  Type of KnKey
//
//----------------------------------------------------------------------------------------------
const KnClientType knClientType(const KnKey knKey);

//----------------------------------------------------------------------------------------------
//
//  Encrypt
//   - data : Data to be encrypted.
//   - origin : Originator of encryption, either server or client
//   - knKey : KnKey obtained using either KnoxenClient or KnoxenServer calls.
//
//  Return
//   - KnData if successful
//   - NULL if error. Use knError() to retrieve error description.
//
//  Use knDataFree to free the KnData memory.
//
//----------------------------------------------------------------------------------------------
KnData knEncrypt(const KnData data, const KnOrigin origin, const KnKey knKey);

//----------------------------------------------------------------------------------------------
//
//  Decrypt
//   - packet : Knoxen data packet to be decrypted.
//   - origin : Originator of encryption, either server or client
//   - knKey : KnKey obtained using either KnoxenClient or KnoxenServer calls.
//
//  Return
//   - KnData if successful
//   - NULL if error. Use knError() to retrieve error description.
//
//  Use knDataFree to free the KnData memory.
//
//----------------------------------------------------------------------------------------------
KnData knDecrypt(const KnData packet, const KnOrigin origin, const KnKey knKey);

//----------------------------------------------------------------------------------------------
//
//  Refresh Knoxen key
//   - knKey : KnKey
//   - data : Data used in refreshing keys
//
//  Return
//   - true if crypt key and hmac key both updated using nonce
//   - false if error. Use knError() to retrieve error description.
//
//  KnData data must be non-empty.
//
//----------------------------------------------------------------------------------------------
bool knKeyRefresh(KnKey knKey, const KnData data);

//----------------------------------------------------------------------------------------------
//
//  Free an KnString.
//
//----------------------------------------------------------------------------------------------
void knStringFree(KnString string);

//----------------------------------------------------------------------------------------------
//
//  Free an KnData. If the underlying memory is owned by this data, the memory is both
//  cleared and freed; otherwise only the KnData struct is freed.
//
//----------------------------------------------------------------------------------------------
void knDataFree(KnData data);

//----------------------------------------------------------------------------------------------
//
//  Clear and free an KnKeyAgreementd.
//
//----------------------------------------------------------------------------------------------
void knKeyAgreementFree(KnKeyAgreement keyAgreement);

//----------------------------------------------------------------------------------------------
//
//  Clear and free an KnKey.
//
//----------------------------------------------------------------------------------------------
void knKeyFree(KnKey knKey);

//----------------------------------------------------------------------------------------------
//
//  Free static memory used by Knoxen client and server libraries.
//
//----------------------------------------------------------------------------------------------
void knCleanup(void);

#endif
