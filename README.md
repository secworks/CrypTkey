# CrypTkey
The CrypTech HSM implemented on a Tillitis Tkey.


## Status
Just started. Not completed. **Does. Not. Work.**


## Introduction
**The CrypTech HSM**
[The CrypTech project](https://cryptech.is/) developed the first truly
open High Security Module capable of supporting PKCS11, provide a
number of hardware accelerated functions - for example Elliptic Curve
and RSA generation and usage. High performance secure hashing, key
derivation and key wrapping. And high performance, best in class
random number generation.


**The Tillitis Tkey**
[Tillitis](https://tillitis.se/) has developed the [fully open]()
secure token and application platform
[Tkey](https://tillitis.se/products/tkey/). The Tkey System on Chip
(SoC) includes a RISC-V processor and provides the functionality
needed to load and execute device applications capable of performing
signing, SSH, key derivation etc.

Crucially, the Tkey supports measured loading of device applications
using the
[DICE](https://www.microsoft.com/en-us/research/project/dice-device-identifier-composition-engine/)
mechanism to ensure application authentication and provisioning of the
application base secret.


**CrypTkey**
The CrypTkey project tries to combine CrypTech with the Tkey. The goal
is to provide a secure System on Chip based on the Tkey capable of
implementing the CrypTech HSM as a device application.

As a first step the Tkey is ported to the [Radiona
ULX3S](https://radiona.org/ulx3s/) board equipped with the Lattice
ECP-85F FPGA.the ULX3S FPGA board. The Tkey design is then expanded
and modified to provide the functionality and performance reqquired to
support the CrypTech HSM as a device application.


## Features
A non exthausive, quite fuzzy list of features. More wild ideas really:

- RISC-V based SoC with cores needed to support the CrypTech HSM.This
  inlcudes timers, watchdog, interrupt, UART, SPI.

- At least 50+ MHz clock.

- 32 MByte SDRAM for application.

- Compact NIST SP 800 90-ish, high performance secure random number
  generator. In comparison to Tkey, there will be no direct access to
  the true random number generator, instead more like the RNG in
  Cryptech. But more compact.

- Cores for SHA-256, SHA-3, Blake2s. And wrappers to support HMAC,
  and HKDF.

- AES with at least CBC, CTR and CMAC modes.. Possibly GCM and
  KEYWRAP.

- Core for acceleration of RSA. Key generation and key usage.

- Core for EdDSA with Ed25519.

- Core for acceleration of Elliptic Curves (EC) operatioms. And ECDSA
  with P-256, P-384 and P-521 curves.

- Ability to store keys and data to be used for performing signing,
  wrapping etc.

- Ability to extend the functionality through measured application
  loading (as done in the Tkey).


## Threat model
Basically To Be Written.

Since the FPGA is SRAM based and requires an external storage of the
bitsrtream, we can't store the Universal Device Secret (UDS) inside
the FPGA. This means that all attacks on the PCB are out of
scope. Unless we figure out a way to be able to store the UDS in a
battery baxcked memory in a secure way, similar to the Master Key
Memory (MKM) in CrypTech.

---
