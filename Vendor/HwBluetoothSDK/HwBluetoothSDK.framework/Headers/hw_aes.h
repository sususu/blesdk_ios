#ifndef Hw_AES_H_
#define Hw_AES_H_

#include <stdint.h>

// #define the macros below to 1/0 to enable/disable the mode of operation.
//
// kHwCBC enables AES encryption in kHwCBC-mode of operation.
// kHwCTR enables encryption in counter-mode.
// kHwECB enables the basic kHwECB 16-byte block algorithm. All can be enabled simultaneously.

// The #ifndef-guard allows it to be configured before #include'ing or at compile time.
#ifndef kHwCBC
  #define kHwCBC 1
#endif

#ifndef kHwECB
  #define kHwECB 1
#endif

#ifndef kHwCTR
  #define kHwCTR 1
#endif


#define kHwAES128 1
//#define kHwAES192 1
//#define kHwAES256 1

#define kHwAES_BLOCKLEN 16 //Block length in bytes AES is 128b block only

#if defined(kHwAES256) && (kHwAES256 == 1)
    #define kHwAES_KEYLEN 32
    #define kHwAES_keyExpSize 240
#elif defined(kHwAES192) && (kHwAES192 == 1)
    #define kHwAES_KEYLEN 24
    #define kHwAES_keyExpSize 208
#else
    #define kHwAES_KEYLEN 16   // Key length in bytes
    #define kHwAES_keyExpSize 176
#endif

struct hwAES_ctx
{
  uint8_t RoundKey[kHwAES_keyExpSize];
#if (defined(kHwCBC) && (kHwCBC == 1)) || (defined(kHwCTR) && (kHwCTR == 1))
  uint8_t Iv[kHwAES_BLOCKLEN];
#endif
};

void hwAES_init_ctx(struct hwAES_ctx* ctx, const uint8_t* key);
#if (defined(kHwCBC) && (kHwCBC == 1)) || (defined(kHwCTR) && (kHwCTR == 1))
void hwAES_init_ctx_iv(struct hwAES_ctx* ctx, const uint8_t* key, const uint8_t* iv);
void hwAES_ctx_set_iv(struct hwAES_ctx* ctx, const uint8_t* iv);
#endif

#if defined(kHwECB) && (kHwECB == 1)
// buffer size is exactly kHwAES_BLOCKLEN bytes;
// you need only hwAES_init_ctx as IV is not used in kHwECB
// NB: kHwECB is considered insecure for most uses
void hwAES_ECB_encrypt(struct hwAES_ctx* ctx, uint8_t* buf);
void hwAES_ECB_decrypt(struct hwAES_ctx* ctx, uint8_t* buf);

#endif // #if defined(kHwECB) && (kHwECB == !)


#if defined(kHwCBC) && (kHwCBC == 1)
// buffer size MUST be mutile of kHwAES_BLOCKLEN;
// Suggest https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS7 for padding scheme
// NOTES: you need to set IV in ctx via hwAES_init_ctx_iv() or hwAES_ctx_set_iv()
//        no IV should ever be reused with the same key 
void hwAES_CBC_encrypt_buffer(struct hwAES_ctx* ctx, uint8_t* buf, uint32_t length);
void hwAES_CBC_decrypt_buffer(struct hwAES_ctx* ctx, uint8_t* buf, uint32_t length);

#endif // #if defined(kHwCBC) && (kHwCBC == 1)


#if defined(kHwCTR) && (kHwCTR == 1)

// Same function for encrypting as for decrypting. 
// IV is incremented for every block, and used after encryption as XOR-compliment for output
// Suggesting https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS7 for padding scheme
// NOTES: you need to set IV in ctx with hwAES_init_ctx_iv() or hwAES_ctx_set_iv()
//        no IV should ever be reused with the same key 
void hwAES_CTR_xcrypt_buffer(struct hwAES_ctx* ctx, uint8_t* buf, uint32_t length);

#endif // #if defined(kHwCTR) && (kHwCTR == 1)


#endif //Hw_AES_H_
