# SRNG
Secure Random Number Generator

## Description
This core implemnents a cryptographically secure random number generator (RNG).

The SRNG core is based on a ring oscillator based True Random Number
Generator (TRNG). The TRNG perform von Neumann conditioning.

The TRNG is used to periodically seed a hash based digital random bit
generator (DRBG). The hash function used is Blake2s.
