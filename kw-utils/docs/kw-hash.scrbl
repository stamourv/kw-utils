#lang scribble/manual
@(require scribble/eval
          (for-label kw-utils/kw-hash
                     kw-utils/kw-hash-lambda
                     kw-utils/keyword-lambda
                     racket/base
                     racket/contract/base
                     racket/math
                     ))

@title[#:tag "kw-hash.scrbl"]{kw-hash}

@section{kw-hash-lambda}

@defmodule[kw-utils/kw-hash-lambda]

@defform[(kw-hash-lambda formals #:kws kw-hash-id body-expr ...+)]{
roughly equivalent to
@(racketblock
  (keyword-lambda (kws kw-args . formals)
    (let ([kw-hash-id (keyword-apply make-kw-hash kws kw-args '())])
      body ...)))

@examples[
  (require kw-utils/kw-hash-lambda)
  (define proc
    (kw-hash-lambda rest-args #:kws kw-hash
      (list rest-args kw-hash)))
  (proc 0 1 2 #:a 'a #:b 'b)
]}

@section{kw-hash}

@defmodule[kw-utils/kw-hash]

@defproc[(apply/kw-hash [proc procedure?] [kw-hash (hash/c keyword? any/c)] [v any/c] ... [lst list?])
         any]{
like @racket[keyword-apply], but instead of taking the keywords and keyword
arguments as separate lists, @racket[apply/kw-hash] takes them in a hash-table.

Based on @url["https://gist.github.com/Metaxal/578b473bc48886f81123"].

@examples[
  (require kw-utils/kw-hash racket/math)
  (define (kinetic-energy #:m m #:v v)
    (* 1/2 m (sqr v)))
  (apply/kw-hash kinetic-energy (hash '#:m 2 '#:v 1) '())
]}

@defproc[(app/kw-hash [proc procedure?] [kw-hash (hash/c keyword? any/c)] [v any/c] ...)
         any]{
like @racket[apply/kw-hash], but doesn't take a list argument at the end.
}

@defproc[(make-kw-hash [#:<kw> kw-arg any/c] ...) (hash/c keyword? any/c)]{
returns a hash-table containing the given keyword arguments.
}
