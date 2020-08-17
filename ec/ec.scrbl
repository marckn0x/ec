#lang scribble/manual

@(require (for-label racket)
          (for-label ec))

@title{Elliptic Curves}

@author[(author+email "Marc Burns" "marc@kn0x.io")]

@defmodule[ec]

Provides Racket implementations of elliptic curve arithmetic over prime fields
in Jacobian coordinates, efficient integer multiplication in the elliptic curve
group, affine/Jacobian coordinate conversion, and @cite{SEC1} point
serialization.

Provides parameters for several popular cryptographic elliptic curves.

This library should not be used to process information that must be kept secret.
No effort has been made to secure this implementation against side-channel
attacks.

For common cryptographic operations over elliptic curves, please see the
@racketmodname[crypto] module.

@section{Curves}

@defstruct[curve ([a integer?]
                  [b integer?]
                  [P exact-nonnegative-integer?]
                  [Gx exact-nonnegative-integer?]
                  [Gy exact-nonnegative-integer?]
                  [n exact-nonnegative-integer?]
                  [bytes exact-nonnegative-integer?])]{
 Represents the elliptic curve @math{y^2 = x^3 + ax + b} over the prime field @math{ℤ/Pℤ}
 together with a point @math{(Gx, Gy)} that generates a cyclic group of order @math{n}.

 When (de)serializing points in SEC format, assumes each coordinate has
 length @racketfont{bytes} bytes.
}

@defstruct[jacobian-point ([x exact-nonnegative-integer?]
                           [y exact-nonnegative-integer?]
                           [z exact-nonnegative-integer?]
                           [id boolean?]
                           [curve curve?])]{
 When @racketfont{id} is not @racket[#f], represents the
 @hyperlink["https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_at_infinity"]{point at infinity}.
 Otherwise, represents a point on the elliptic curve @racketfont{curve} with
 @hyperlink["http://hyperelliptic.org/EFD/g1p/auto-jquartic-2xyz.html"]{doubling-oriented XYZ Jacobian coordinates} @math{(x, y, z)}.
}

@defstruct[affine-point ([x exact-nonnegative-integer?]
                         [y exact-nonnegative-integer?]
                         [id boolean?]
                         [curve curve])]{
 When @racketfont{id} is not @racket[#f], represents the
 @hyperlink["https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication#Point_at_infinity"]{point at infinity}.
 Otherwise, represents a point on the elliptic curve @racketfont{curve} with
 affine coordinates @math{(x, y)}. These coordinates are field elements
 that satisfy the curve equation @math{y^2 = x^3 + ax + b} if and only if the
 point is on the curve.
}

@defproc[(affine->jacobian [p affine-point?]) jacobian-point?]{
 Changes coordinates of a point from affine to Jacobian. This operation is cheap.
}

@defproc[(jacobian->affine [p jacobian-point?]) affine-point?]{
 Changes coordinates of a point from Jacobian to affine. This operation is
 expensive because it requires finding the inverse of a field element.
}

@defproc[(on-curve? [p affine-point?]) boolean?]{
 Checks whether @racketfont{p} satisfies the elliptic curve equation
 @math{y^2 = x^3 + ax + b} for the curve associated with @racketfont{p}.
}

@section{Curve Operations}

@defproc[(ecdub [p jacobian-point?]) jacobian-point?]{
 Doubles an elliptic curve point.
}

@defproc[(ec+ [p jacobian-point?] [q jacobian-point?]) jacobian-point?]{
 Adds two elliptic curve points @racketfont{p} and @racketfont{q}. If @racketfont{p} and
 @racketfont{q} are equal, this function will dispatch to @racket[ecdub].
}

@defproc[(dG [c curve?] [d exact-nonnegative-integer?]) jacobian-point?]{
 Multiplies the generator of curve @racketfont{c} by @racketfont{d}.
 This is the same as calling @racket[dO] on @math{(Gx, Gy)} and @racketfont{d}.
}

@defproc[(dO [O jacobian-point?] [d exact-nonnegative-integer?]) jacobian-point?]{
 Multiplies curve point @racketfont{O} by @racketfont{d}.
 The same result could be achieved by repeatedly adding @racketfont{O}
 to itself @racketfont{d} times, but @racketfont{dO} is much more efficient.
}

@section{SEC Point Representation}

@defproc[(point->sec [p affine-point?] [#:compressed? compressed? any/c #t]) bytes?]{
 Serializes point @racketfont{p} to its @cite{SEC1} representation.
 When @racket[compressed?] is @racket[#f], both coordinates are stored.
 Otherwise, only the @math{x} coordinate and the parity of the @math{y}
 coordinate are stored.
}

@defproc[(sec->point [c curve?] [s bytes?]) affine-point?]{
 Deserializes the SEC representation @racketfont{s} of a point on curve @racketfont{c}.
}

@section{Parameters}

@deftogether[(@defthing[secp112r1 curve?]
               @defthing[secp112r2 curve?]
               @defthing[secp128r1 curve?]
               @defthing[secp128r2 curve?]
               @defthing[secp160k1 curve?]
               @defthing[secp160r1 curve?]
               @defthing[secp160r2 curve?]
               @defthing[secp192k1 curve?]
               @defthing[secp192r1 curve?]
               @defthing[secp224k1 curve?]
               @defthing[secp224r1 curve?]
               @defthing[secp256k1 curve?]
               @defthing[secp256r1 curve?]
               @defthing[secp384r1 curve?]
               @defthing[secp521r1 curve?])]{
 @cite{SEC2} recommended curve parameters.
}

@(bibliography
  (bib-entry
   #:key "SEC1"
   #:title "SEC 1: Elliptic Curve Cryptography, version 2.0"
   #:author "Certicom Research"
   #:date "2009"
   #:url "https://www.secg.org/sec1-v2.pdf")
  (bib-entry
   #:key "SEC2"
   #:title "SEC 2: Recommended Elliptic Curve Domain Parameters, version 1.0"
   #:author "Certicom Research"
   #:date "2000"
   #:url "https://www.secg.org/SEC2-Ver-1.0.pdf"))

