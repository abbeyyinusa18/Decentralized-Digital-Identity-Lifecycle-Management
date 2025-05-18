;; Attribute Management Contract
;; Handles identity claims updates

(define-data-var admin principal tx-sender)

;; Map to store identity attributes
;; Maps identity (principal) -> attribute name -> attribute value
(define-map identity-attributes { identity: principal, attr-name: (string-ascii 64) } (string-utf8 256))

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-invalid-attribute (err u102))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Add or update an attribute for an identity
(define-public (set-attribute (identity principal) (attr-name (string-ascii 64)) (attr-value (string-utf8 256)))
  (begin
    ;; Only the identity owner or admin can set attributes
    (asserts! (or (is-eq tx-sender identity) (is-admin)) err-not-authorized)
    (ok (map-set identity-attributes { identity: identity, attr-name: attr-name } attr-value))))

;; Get an attribute for an identity
(define-read-only (get-attribute (identity principal) (attr-name (string-ascii 64)))
  (map-get? identity-attributes { identity: identity, attr-name: attr-name }))

;; Delete an attribute
(define-public (delete-attribute (identity principal) (attr-name (string-ascii 64)))
  (begin
    (asserts! (or (is-eq tx-sender identity) (is-admin)) err-not-authorized)
    (ok (map-delete identity-attributes { identity: identity, attr-name: attr-name }))))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set admin new-admin))))
