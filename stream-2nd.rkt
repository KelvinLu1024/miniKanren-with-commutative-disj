#lang racket
#|

an efficient, but very nonobviously correct way

represent
  - (@null) with '()
  - (@list x) with `(,x)
  - (@append xs ys) with `(,xs . ,ys),
    where xs and ys are not (@null)

|#
(provide empty-inf
         mature-inf
         immature-inf
         append-inf
         append-map-inf
         take-inf
         empty-inf?
         has-mature-inf?
         first-mature-inf
         force-inf)

#| @List × @List → @List |#
(define (@++ x y)
  (cond
    [(null? x) y]
    [(null? y) x]
    [else (cons x y)]))

#| @List → X × @List |#
(define (@car+cdr x)
  (let ([a (car x)]
        [d (cdr x)])
    (cond
      [(null? d) (cons a '())]
      [else
       (let loop ([a (car a)]
                  [d (cdr a)]
                  [acc d])
         (cond
           [(null? d) (cons a acc)]
           [else
            (loop (car a) (cdr a) (cons d acc))]))])))

(define (empty-inf? s-inf)
  (and (null? (car s-inf))
       (null? (cdr s-inf))))

(define (has-mature-inf? s-inf)
  (not (null? (car s-inf))))

(define (first-mature-inf s-inf)
  (car (car s-inf)))

; the mature part must be empty
(define (force-inf s-inf)
  (let ([th+rest (@car+cdr (cdr s-inf))])
    (let ([th (car th+rest)])
      (append-inf (cons '() (cdr th+rest)) (th)))))

(define (empty-inf) (cons '() '()))
(define (mature-inf v) (cons (list v) '()))
(define (immature-inf th) (cons '() (list th)))

#| Stream × Stream → Stream |#
(define (append-inf s-inf t-inf)
  (cons (append (car s-inf) (car t-inf))
    (@++ (cdr s-inf) (cdr t-inf))))

#| Nat × Stream → (List X) |#
(define (take-inf n s-inf)
  (let loop ([n n] [vs (car s-inf)])
    (cond
      [(and n (zero? n)) '()]
      [(null? vs)
       (let ([ths (cdr s-inf)])
         (cond
           [(null? ths) '()]
           [else (take-inf n (force-inf s-inf))]))]
      [else
       (cons (car vs)
         (loop (and n (sub1 n)) (cdr vs)))])))

#| (State → Stream) × Stream → Stream |#
(define (append-map-inf g s-inf)
  (let outer ((vs (car s-inf)))
    (cond
      [(null? vs)
       (cons '()
         (let inner ([ths (cdr s-inf)])
           (cond
             [(null? ths) '()]
             [else
              (let ([th+rest (@car+cdr ths)])
                (let ([th (car th+rest)])
                  (@++
                   (list (lambda ()
                           (append-map-inf g (th))))
                   (inner (cdr th+rest)))))])))]
      [else
       (append-inf (g (car vs)) (outer (cdr vs)))])))