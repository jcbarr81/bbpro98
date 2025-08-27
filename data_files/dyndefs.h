/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
   Copyright 1991-1997 Sierra On-Line.  All Rights Reserved.

   This code is copyrighted and intended as an aid in writing utilities
   for the Front Page Sports Football products.  All rights reserved.

   THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF 
   ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A 
   PARTICULAR PURPOSE.


   dyndefs.h

   Dynamix global typedefs for easy access across comilers

   GJW: 6-2-1992, original creation
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */

#ifndef  _DYNDEFS_H
#define  _DYNDEFS_H

#ifndef _WINDOWS_
// GJW: 2-15-1995, far is invalid in 32 bit, so make it a define
#ifdef   __FLAT__
#define NEAR
#define FAR
#define HUGE
#else
#define NEAR   near
#define FAR    far
#define HUGE   huge
#endif
#endif	// #ifndef _WINDOWS_

// storage identifiers
typedef char               DYN_8;
typedef short              DYN_16;
typedef long               DYN_32;
typedef unsigned char      DYN_U_8;
typedef unsigned short     DYN_U_16;
typedef unsigned long      DYN_U_32;

// function helpers:
// first block is the return type
// second are the parameters
// C = char, F = far, S = short, P = pointer modifier (i.e. SP = *short),
// V = void


#ifdef  TRUE
#undef  TRUE 
#undef  FALSE 
#endif
#define TRUE  1
#define FALSE 0

#define BOTTOM_HALF_SCREEN_ONLY 0x0001

#endif   // _DYNDEFS_H