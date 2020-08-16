#lang scribble/manual

@(require (for-label racket))

@title{Elliptic Curves}

@defmodule[ecc]

Provides Racket implementations of elliptic curve point addition and doubling
in Jacobian coordinates, efficient integer multiplication in the elliptic curve
group, and of conversion between affine and Jacobian coordinates.

Provides parameters for several popular cryptographic elliptic curves.

@section{Curves}

@defstruct[curve ([a integer?][b integer?][P exact-nonnegative-integer?][Gx exact-nonnegative-integer?][Gy exact-nonnegative-integer?][n exact-nonnegative-integer?])]{
  Represents the elliptic curve y^2 = x^3 + ax + b over the prime field Z/PZ
  together with a point (Gx, Gy) that generates a group of order n.
}

@defstruct[jacobian-point ([x exact-nonnegative-integer?][y exact-nonnegative-integer?][z exact-nonnegative-integer?][id boolean?][curve curve?])]{
  When @racket[id] is not @racket[false], represents the point at infinity.
  Otherwise, represents a point on the elliptic curve @racket[curve] with Jacobian coordinates x, y, z.
}

@defstruct[affine-point ([x exact-nonnegative-integer?][y exact-nonnegative-integer?][z exact-nonnegative-integer?][id boolean?][curve curve])]{
  When @racket[id] is not @racket[false], represents the point at infinity.
  Otherwise, represents a point on the elliptic curve @racket[curve] with affine coordinates x, y.
}

@defproc[(affine->jacobian [p affine-point?]) jacobian-point?]{
  Changes coordinates of a point from affine to Jacobian. This operation is cheap.
}

@defproc[(jacobian->affine [p jacobian-point?]) affine-point?]{
  Changes coordinates of a point from Jacobian to affine. This operation is
  expensive because it requires finding the inverse of a field element.
}

@section{Curve Operations}

@defproc[(ecdub [j jacobian-point?]) jacobian-point?]{
  Doubles an elliptic curve point.
}

@defproc[(ec+ [p jacobian-point?] [q jacobian-point?]) jacobian-point?]{
  Adds two elliptic curve points @racket[p] and @racket[q]. If @racket[p] and
  @racket[q] are equal, this function will dispatch to @racket[ecdub].
}

@defproc[(dG [c curve?] [d exact-nonnegative-integer?]) jacobian-point?]{
  Multiplies the generator of curve @racket[c] by @racket[d]. That is,
  repeatedly adds the curve's generator point (Gx, Gy) to itself @racket[d]
  times.
}

@section{Parameters}

@defthing[secp112r1 curve?]{
  SECG SEC 2 @racket[secp112r1] curve
}

@defthing[secp128r1 curve?]{
  SECG SEC 2 @racket[secp128r1] curve
}

@defthing[secp128r2 curve?]{
  SECG SEC 2 @racket[secp128r2] curve
}

@defthing[secp160k1 curve?]{
  SECG SEC 2 @racket[secp160k1] curve
}

@defthing[secp160r1 curve?]{
  SECG SEC 2 @racket[secp160r1] curve
}

@defthing[secp160r2 curve?]{
  SECG SEC 2 @racket[secp160r2] curve
}

@defthing[secp192k1 curve?]{
  SECG SEC 2 @racket[secp192k1] curve
}

@defthing[secp192r1 curve?]{
  SECG SEC 2 @racket[secp192r1] curve
}

@defthing[secp224k1 curve?]{
  SECG SEC 2 @racket[secp224k1] curve
}

@defthing[secp224r1 curve?]{
  SECG SEC 2 @racket[secp224r1] curve
}

@defthing[secp256k1 curve?]{
  SECG SEC 2 @racket[secp256k1] curve
}

@defthing[secp256r1 curve?]{
  SECG SEC 2 @racket[secp256r1] curve
}

@defthing[secp384r1 curve?]{
  SECG SEC 2 @racket[secp384r1] curve
}

@defthing[secp521r1 curve?]{
  SECG SEC 2 @racket[secp521r1] curve
}
