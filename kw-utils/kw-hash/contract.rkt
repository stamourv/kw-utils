#lang racket/base

(provide kw-hash->)

(require racket/contract/base
         racket/contract/combinator
         racket/local
         "../keyword-lambda.rkt"
         "../kw-hash.rkt"
         (for-syntax racket/base
                     syntax/parse
                     ))
(module+ test
  (require rackunit racket/contract/region))

(define-syntax kw-hash->
  (lambda (stx)
    (syntax-parse stx #:literals (any)
      [(kw-hash-> [arg/c ...] #:kws kw-hash/c any)
       #:declare arg/c (expr/c #'chaperone-contract? #:name "argument contract")
       #:declare kw-hash/c (expr/c #'chaperone-contract? #:name "kw-hash contract")
       (syntax/loc stx
         (make-kw-hash->any (list arg/c.c ...) kw-hash/c.c))]
      )))

(define (make-kw-hash->any arg-ctcs kw-hash-ctc)
  (make-chaperone-contract
   #:name `(kw-hash-> ,(map contract-name arg-ctcs)
                      #:kws ,(contract-name kw-hash-ctc)
                      any)
   #:first-order procedure?
   #:projection (make-kw-hash->any-proj
                 (map contract-projection arg-ctcs)
                 (contract-projection kw-hash-ctc))))

(define ((make-kw-hash->any-proj arg-projs kw-hash-proj) blame)
  ;; arg-wrappers : (Listof [Arg -> Arg])
  (define arg-wrappers
    (get-arg-wrappers blame arg-projs))
  ;; kws-wrapper : [Kws-Hash -> Kws-Hash]
  (define kws-wrapper
    (get-arg-wrapper blame kw-hash-proj "the keywords of"))
  (lambda (f)
    (check-procedure blame f)
    (chaperone-procedure
     f
     (keyword-lambda (kws kw-args . args)
       (check-length blame f (length args) (length arg-wrappers))
       (define args*
         (map app arg-wrappers args))
       (define kw-hash*
         (kws-wrapper (keyword-app-make-kw-hash kws kw-args)))
       ;; kw-args* has to be in the same order as kw-args
       (define kw-args*
         (map-hash-ref kw-hash* kws))
       (if (null? kw-args*)
           ;; if no keywords were passed in, don't include them
           (apply values args*)
           (apply values kw-args* args*))))))

(define (check-procedure blame f)
  (unless (procedure? f)
    (raise-blame-error blame f '(expected: "procedure?" given: "~e") f)))

(define (check-length blame f actual-length expected-length)
  (unless (= actual-length expected-length)
    (raise-blame-error (blame-swap blame) f
                       '(expected: "~v arguments" given: "~v non-keyword arguments")
                       expected-length actual-length)))

(define (app f a)
  (f a))

(define (map-hash-ref hash lst)
  (for/list ([key (in-list lst)])
    (hash-ref hash key)))

(define (get-arg-wrapper blame proj context)
  (define arg-blame
    (blame-add-context blame context #:swap? #t))
  (proj arg-blame))

(define (get-arg-wrappers blame arg-projs)
  (for/list ([proj (in-list arg-projs)]
             [i (in-naturals)])
    (get-arg-wrapper blame proj (format "argument ~v of" i))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(module+ test
  (define c
    (kw-hash-> [number? (listof symbol?)] #:kws (hash/c keyword? string?) any))
  (check-pred chaperone-contract? c)
  (check-equal? (contract-name c)
                '(kw-hash-> [number? (listof symbol?)] #:kws (hash/c keyword? string?) any))
  (define/contract (f x syms #:hello [hello "hello"])
    c
    x)
  (check-equal? (f 3 '(a b c)) 3)
  (check-exn exn:fail:contract:blame?
             (λ () (f 'three '(a b c))))
  (check-exn exn:fail:contract:blame?
             (λ () (f 3 '(one two 5))))
  (check-exn exn:fail:contract:blame?
             (λ () (f 3 '(a b c) #:hello 'not-a-string)))
  )