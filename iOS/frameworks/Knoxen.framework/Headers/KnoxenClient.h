//
//  KnoxenClient.h
//  Knoxen
//
//  Created by Paul Rogers on 10/8/15.
//  © 2016-2017 Knoxen, LLC. All rights reserved.
//
//
//  CxTBD Description
//
#ifndef KNOXEN_CLIENT_H
#define KNOXEN_CLIENT_H

#include "KnoxenLib.h"

//==============================================================================================
//
//  Lib Key Agreement
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
//  Create Lib Key Agreement.
//
//  The returned KnKeyAgreement will be freed on the call to knKeyAgreementFinalize
//
//----------------------------------------------------------------------------------------------
KnKeyAgreement knLibKeyAgreement(void);

//----------------------------------------------------------------------------------------------
//
//  Create Lib Key Exchange Request. The keyAgreement param is updated.
//
//  The returned KnData must be freed using knDataFree.
//
//----------------------------------------------------------------------------------------------
KnData knCreateLibKeyExchangeRequest(KnKeyAgreement keyAgreement,
                                     const KnData exchangeData);

//----------------------------------------------------------------------------------------------
//
//  Process Lib Key Exchange Response. The keyAgreement param is updated.
//
//----------------------------------------------------------------------------------------------
bool knProcessLibKeyExchangeResponse(KnKeyAgreement keyAgreement,
                                     const KnData exchangeResponse);

//----------------------------------------------------------------------------------------------
//
//  Create Lib Key Confirm Request. The keyAgreement param is updated.
//
//  The returned KnData must be freed using knDataFree.
//
//----------------------------------------------------------------------------------------------
KnData knCreateLibKeyConfirmRequest(KnKeyAgreement keyAgreement,
                                    const KnData confirmData);

//----------------------------------------------------------------------------------------------
//
//  Process Lib Key Confirm Response. The keyAgreement param is updated.
//
//----------------------------------------------------------------------------------------------
bool knProcessLibKeyConfirmResponse(KnKeyAgreement keyAgreement,
                                    const KnData confirmResponse);

//==============================================================================================
//
//  User Key Agreement
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
//  Create User Key Agreement.
//
//  The returned KnKeyAgreement will be freed on the call to knKeyAgreementFinalize
//
//----------------------------------------------------------------------------------------------
KnKeyAgreement knUserKeyAgreement(const KnClientType type,
                                  const KnKey knKey,
                                  const char * userId);

//----------------------------------------------------------------------------------------------
//
//  Create User Key Exchange Request. The keyAgreement param is updated.
//
//  The returned KnData must be freed using knDataFree.
//
//----------------------------------------------------------------------------------------------
KnData knCreateUserKeyExchangeRequest(KnKeyAgreement keyAgreement,
                                      const KnData exchangeData);

//----------------------------------------------------------------------------------------------
//
//  Process User Key Exchange Response. The keyAgreement param is updated.
//
//----------------------------------------------------------------------------------------------
bool knProcessUserKeyExchangeResponse(KnKeyAgreement keyAgreement,
                                      const char * password,
                                      const KnData exchangeResponse);

//----------------------------------------------------------------------------------------------
//
//  Create User Key Confirm Request. The keyAgreement param is updated.
//
//  The returned KnData must be freed using knDataFree.
//
//----------------------------------------------------------------------------------------------
KnData knCreateUserKeyConfirmRequest(KnKeyAgreement keyAgreement,
                                     const KnData confirmData);

//----------------------------------------------------------------------------------------------
//
//  Process Lib Key Confirm Response. The keyAgreement param is updated.
//
//----------------------------------------------------------------------------------------------
bool knProcessUserKeyConfirmResponse(KnKeyAgreement keyAgreement,
                                     const KnData confirmResponse);

//==============================================================================================
//
//  Key Agreement Data
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
//  Key Agreement Client Id.
//
//----------------------------------------------------------------------------------------------
const char * knKeyAgreementClientId(const KnKeyAgreement keyAgreement);

//----------------------------------------------------------------------------------------------
//
//  Key Agreement Crypt Key
//
//----------------------------------------------------------------------------------------------
const KnKey knKeyAgreementExchKey(const KnKeyAgreement keyAgreement);

//----------------------------------------------------------------------------------------------
//
//  Key Agreement Exchange Data
//
//----------------------------------------------------------------------------------------------
const KnData knKeyAgreementExchangeData(const KnKeyAgreement keyAgreement);

//----------------------------------------------------------------------------------------------
//
//  Key Agreement Confirm Data
//
//----------------------------------------------------------------------------------------------
const KnData knKeyAgreementConfirmData(const KnKeyAgreement keyAgreement);

//==============================================================================================
//
//  Finalize Key Agreement
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
//  Finalize Key Agreement. The keyAgreement param is freed during agreement finalization.
//
//  The returned KnKey must be freed using knKeyFree.
//
//----------------------------------------------------------------------------------------------
KnKey knKeyAgreementFinalize(KnKeyAgreement keyAgreement);

//==============================================================================================
//
//  User Registration
//
//==============================================================================================
//----------------------------------------------------------------------------------------------
//
//  Create Registration
//
//  The returned KnRegistration must be freed using knRegistrationFree.
//
//----------------------------------------------------------------------------------------------
const KnRegistration knRegistration(const char * identity,
                                    const char * password,
                                    KnRegistrationCode code);

//----------------------------------------------------------------------------------------------
//
//  Create Registration Request
//
//  The returned KnData must be freed using knDataFree.
//
//----------------------------------------------------------------------------------------------
KnData knCreateRegistrationRequest(const KnRegistration registration, const KnData requestData);

//----------------------------------------------------------------------------------------------
//
//  Process Registration Response
//
//----------------------------------------------------------------------------------------------
bool knProcessRegistrationResponse(const KnKey knKey,
                                   const KnRegistration registration,
                                   const KnData registrationResponsePacket);

//----------------------------------------------------------------------------------------------
//
//  Free Registration
//
//----------------------------------------------------------------------------------------------
void knRegistrationFree(KnRegistration registration);

//==============================================================================================
//
//  SRPC Actions
//
//==============================================================================================
KnData knCreateRegistrationPacket(const KnKey knKey, const KnData data);
KnData knCreateServerTimePacket(const KnKey knKey, const KnData data);
KnData knCreateRefreshPacket(const KnKey knKey, const KnData data);
KnData knCreateClosePacket(const KnKey knKey, const KnData data);

KnData knCreateAppPacket(const KnKey knKey, const KnData data);

#endif
