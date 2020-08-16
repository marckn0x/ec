#lang typed/racket

(provide (struct-out affine-point)
         (struct-out jacobian-point)
         (struct-out curve))

(struct affine-point
  ([x : Nonnegative-Integer]
   [y : Nonnegative-Integer]
   [id : Boolean]
   [curve : curve])
  #:transparent)

(struct jacobian-point
  ([x : Nonnegative-Integer]
   [y : Nonnegative-Integer]
   [z : Nonnegative-Integer]
   [id : Boolean]
   [curve : curve])
  #:transparent)

(struct curve
  ([a : Integer]
   [b : Integer]
   [P : Nonnegative-Integer]
   [Gx : Nonnegative-Integer]
   [Gy : Nonnegative-Integer]
   [n : Nonnegative-Integer]
   [bytes : Nonnegative-Integer])
  #:transparent)