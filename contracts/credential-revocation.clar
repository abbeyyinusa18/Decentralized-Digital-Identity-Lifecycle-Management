;; Credential Revocation Contract
;; Manages invalidation of outdated claims

(define-data-var admin principal tx-sender)

;; Map to store revoked credentials
;; Maps credential ID -> revocation status
(define-map revoked-credentials (string-ascii 64) { revoked: bool, timestamp: uint, reason: (string-utf8 256) })

;; Error codes
(define-constant err-not-admin (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-revoked (err u102))
(define-constant err-not-revoked (err u103))

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin)))

;; Revoke a credential
(define-public (revoke-credential (credential-id (string-ascii 64)) (reason (string-utf8 256)) (issuer principal))
  (begin
    ;; Only the issuer or admin can revoke credentials
    (asserts! (or (is-eq tx-sender issuer) (is-admin)) err-not-authorized)
    (asserts! (is-none (map-get? revoked-credentials credential-id)) err-already-revoked)
    (ok (map-set revoked-credentials credential-id { revoked: true, timestamp: block-height, reason: reason }))))

;; Check if a credential is revoked
(define-read-only (is-revoked (credential-id (string-ascii 64)))
  (match (map-get? revoked-credentials credential-id)
    revocation-info (get revoked revocation-info)
    false))

;; Get revocation details
(define-read-only (get-revocation-details (credential-id (string-ascii 64)))
  (map-get? revoked-credentials credential-id))

;; Reinstate a credential (un-revoke)
(define-public (reinstate-credential (credential-id (string-ascii 64)) (issuer principal))
  (begin
    (asserts! (or (is-eq tx-sender issuer) (is-admin)) err-not-authorized)
    (asserts! (is-some (map-get? revoked-credentials credential-id)) err-not-revoked)
    (ok (map-delete revoked-credentials credential-id))))

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) err-not-admin)
    (ok (var-set admin new-admin))))
