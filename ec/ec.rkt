#lang typed/racket

(require math/number-theory
         "data.rkt")

(provide dG
         dO
         ec+
         ecdub
         affine->jacobian
         jacobian->affine
         on-curve?)

(: affine->jacobian (-> affine-point jacobian-point))
(define (affine->jacobian p)
  (match-define (affine-point x y id? c) p)
  (jacobian-point x y 1 id? c))

(: jacobian->affine (-> jacobian-point affine-point))
(define (jacobian->affine j)
  (match-define (jacobian-point x y z id? (and c (curve _ _ P _ _ _ _))) j)
  (if id?
      (affine-point 0 0 #t c)
      (let* ([z3 (modulo (* z z z) P)]
             [z3-inv (modular-inverse z3 P)]
             [z2-inv (modulo (* z3-inv z) P)])
        (affine-point
         (modulo (* x z2-inv) P)
         (modulo (* y z3-inv) P)
         #f c))))

(: ecdub (-> jacobian-point jacobian-point))
(define (ecdub j)
  (match-define (jacobian-point X Y Z id? (and c (curve a _ P _ _ _ _))) j)
  (if (or id? (= Y 0))
      (jacobian-point 0 0 1 #t c)
      (let* ([S (modulo (* 4 X Y Y) P)]
             [M (modulo (+ (* 3 X X) (* a (modular-expt Z 4 P))) P)]
             [X* (modulo (- (* M M) (* 2 S)) P)]
             [Y* (modulo (- (* M (- S X*)) (* 8 (modular-expt Y 4 P))) P)]
             [Z* (modulo (* 2 Y Z) P)])
        (jacobian-point X* Y* Z* #f c))))

(: ec+ (-> jacobian-point jacobian-point jacobian-point))
(define (ec+ p q)
  (match-define (jacobian-point X1 Y1 Z1 id1? c1) p)
  (match-define (jacobian-point X2 Y2 Z2 id2? (and c2 (curve _ _ P _ _ _ _))) q)
  (unless (eq? c1 c2)
    (error "cannot add points from different curves"))
  (cond
    [(and id1? id2?) (jacobian-point 0 0 1 #t c1)]
    [id1? q]
    [id2? p]
    [else
     (let* ([U1 (modulo (* X1 Z2 Z2) P)]
            [U2 (modulo (* X2 Z1 Z1) P)]
            [S1 (modulo (* Y1 Z2 Z2 Z2) P)]
            [S2 (modulo (* Y2 Z1 Z1 Z1) P)])
       (if (= U1 U2)
           (if (= S1 S2)
               (ecdub p)
               (jacobian-point 0 0 1 #t c1))
           (let* ([H (- U2 U1)]
                  [R (- S2 S1)]
                  [X3 (modulo (- (* R R) (* H H H) (* 2 U1 H H)) P)]
                  [Y3 (modulo (- (* R (- (* U1 H H) X3)) (* S1 H H H)) P)]
                  [Z3 (modulo (* H Z1 Z2) P)])
             (jacobian-point X3 Y3 Z3 #f c1))))]))

(: on-curve? (-> affine-point Boolean))
(define (on-curve? p)
  (match-define (affine-point x y id? (curve a b P _ _ _ _)) p)
  (if id?
      #t
      (= (modulo (* y y) P)
         (modulo (+ (* x x x) (* a x) b) P))))

(: dG (-> curve Nonnegative-Integer jacobian-point))
(define (dG c d)
  (dO (jacobian-point (curve-Gx c) (curve-Gy c) 1 #f c) d))

(: dO (-> jacobian-point Nonnegative-Integer jacobian-point))
(define (dO O d)
  (let loop ([d : Nonnegative-Integer d]
             [p : jacobian-point O]
             [q : jacobian-point (jacobian-point 0 0 1 #t (jacobian-point-curve O))])
    (if (= d 0)
        q
        (loop
         (quotient d 2)
         (ecdub p)
         (if (= (remainder d 2) 1)
             (ec+ q p)
             q)))))