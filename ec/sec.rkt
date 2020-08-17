#lang typed/racket

(require math/number-theory
         "data.rkt"
         "typed-binaryio.rkt")

(provide sec->point
         point->sec)

(define sec-compressed-even 2)
(define sec-compressed-odd 3)
(define sec-uncompressed 4)

(: point->sec (-> affine-point [#:compressed Any] Bytes))
(define (point->sec p #:compressed [compressed? #t])
  (match-define (affine-point xp yp id? (curve _ _ _ _ _ _ num-bytes)) p)
  (when id?
    (error "cannot serialize the point at infinity"))
  (if compressed?
      (bytes-append
       (bytes
        (if (= (remainder yp 2) 0)
            sec-compressed-even
            sec-compressed-odd))
       (integer->bytes xp num-bytes #f #t))
      (bytes-append
       (bytes sec-uncompressed)
       (integer->bytes xp num-bytes #f #t)
       (integer->bytes yp num-bytes #f #t))))

(: find-nonresidue (-> Nonnegative-Integer Nonnegative-Integer))
(define (find-nonresidue P)
  (: large-random (-> Nonnegative-Integer Nonnegative-Integer))
  (define (large-random num-bytes)
    (bytes->integer
     (list->bytes
      (for/list ([i num-bytes]) (assert (random 0 256) byte?)))
     #f #t))
  (define num-bytes (integer-bytes-length P #f))
  (let loop ([maybe-nr : Nonnegative-Integer (modulo (large-random num-bytes) P)])
    (if (quadratic-residue? maybe-nr P)
        (loop (modulo (large-random num-bytes) P))
        maybe-nr)))

(: factor-twos (-> Nonnegative-Integer (Values Nonnegative-Integer Nonnegative-Integer)))
(define (factor-twos q)
  (let loop ([Q : Nonnegative-Integer q]
             [S : Nonnegative-Integer 0])
    (if (even? Q)
        (loop (quotient Q 2) (add1 S))
        (values Q S))))

(define-type Decompressor (-> Nonnegative-Integer (U 0 1) Nonnegative-Integer))

(: curve=>decompressor (HashTable curve Decompressor))
(define curve=>decompressor (make-hasheq))

(: make-decompressor (-> curve Decompressor))
(define (make-decompressor c)
  (match-define (curve a b P _ _ _ _) c)
  (if (= 3 (modulo P 4))
      
      ;; Fast method (Lagrange's formula)
      (let ([P14 (quotient (add1 P) 4)])
        (lambda ([x : Nonnegative-Integer] [p : (U 0 1)])
          (define ym
            (modular-expt (modulo (+ b (* a x) (modular-expt x 3 P)) P)
                          P14
                          P))
          (if (= (modulo ym 2) p)
              ym
              (modulo (- ym) P))))

      ;; Slow method (Shanks-Tonelli algorithm)
      (let*-values ([(Q S) (factor-twos (assert (sub1 P) exact-nonnegative-integer?))]
                    [(z) (find-nonresidue P)]
                    [(c) (modular-expt z Q P)])
        (lambda ([x : Nonnegative-Integer] [p : (U 0 1)])
          (define y2 (modulo (+ b (* a x) (modular-expt x 3 P)) P))
          (unless (quadratic-residue? y2 P)
            (error "y^2 is not a quadratic residue mod P - is the compressed point corrupt?"))
          (define ym
            (let loop : Nonnegative-Integer
              ([M : Nonnegative-Integer S]
               [c : Nonnegative-Integer c]
               [t : Nonnegative-Integer (modular-expt y2 Q P)]
               [R : Nonnegative-Integer (modular-expt y2 (quotient (add1 Q) 2) P)])
              (cond
                [(= t 0) 0]
                [(= t 1) R]
                [else
                 (define i
                   (let loop2 : Nonnegative-Integer
                     ([i : Nonnegative-Integer 1]
                      [tsq (modulo (* t t) P)])
                     (cond
                       [(= tsq 1) i]
                       [(>= i M) (error "could not find i s.t. t^(2^i) = 1, 0 < i < M")]
                       [else
                        (loop2 (add1 i) (modulo (* tsq tsq) P))])))
                 (define b (modular-expt c (modular-expt 2 (- M i 1) (sub1 P)) P))
                 (define b2 (modulo (* b b) P))
                 (loop i b2 (modulo (* t b2) P) (modulo (* R b) P))])))
          (if (= (modulo ym 2) p)
              ym
              (modulo (- ym) P))))))

(: sec->point (-> curve Bytes affine-point))
(define (sec->point curve s)
  (when (= 0 (bytes-length s))
    (error "invalid empty sec representation"))
  (define num-bytes (curve-bytes curve))
  (match (bytes-ref s 0)
    [(== sec-uncompressed)
     (define expect-length (add1 (* 2 num-bytes)))
     (unless (= expect-length (bytes-length s))
       (error (format "expected ~a bytes for sec uncompressed point" expect-length)))
     (affine-point
      (bytes->integer (subbytes s 1 (add1 num-bytes)) #f #t)
      (bytes->integer (subbytes s (add1 num-bytes)) #f #t)
      #f curve)]
    [(and v (or (== sec-compressed-even) (== sec-compressed-odd)))
     (unless (= (add1 num-bytes) (bytes-length s))
       (error (format "expected ~a bytes for sec compressed point" (add1 num-bytes))))
     (define p (if (= v sec-compressed-even) 0 1))
     (define x (bytes->integer (subbytes s 1) #f #t))
     (affine-point
      x
      ((hash-ref!
        curve=>decompressor
        curve
        (thunk
         (make-decompressor curve)))
       x p)
      #f curve)]))