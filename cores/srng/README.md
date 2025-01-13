# SRNG
Secure Random Number Generator

## Description
This core implemnents a cryptographically secure random number
generator (RNG). The srng is capable of a large amount of random data
and should be able to keep up with the appliction demand running on
the CPU connected to the core.

The SRNG core is based on a ring oscillator True Random Number
Generator (TRNG). The TRNG perform von Neumann conditioning. The core
also implement a simple error dection which checks that the entropy
source is not stuck.

Note that the ring oscillators use explicit instantations of logic
blocks in the Lattice ECP5 FPGA and is therfore not portable without
changing these instantiations. See the source in rtl/trng.v

The TRNG is used to periodically seed a hash based digital random bit
generator (DRBG). The hash function used is Blake2s.
