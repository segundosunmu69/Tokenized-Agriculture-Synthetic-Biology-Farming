;; Producer Verification Contract
;; Manages verification and registration of synthetic biology farmers

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))
(define-constant err-not-verified (err u103))

;; Data structures
(define-map producers
  { producer: principal }
  {
    verified: bool,
    verification-date: uint,
    license-number: (string-ascii 50),
    specialization: (string-ascii 100),
    location: (string-ascii 100)
  }
)

(define-map verification-requests
  { producer: principal }
  {
    requested-at: uint,
    documents-hash: (string-ascii 64),
    status: (string-ascii 20)
  }
)

(define-data-var total-producers uint u0)

;; Public functions
(define-public (request-verification (documents-hash (string-ascii 64)))
  (let ((producer tx-sender))
    (map-set verification-requests
      { producer: producer }
      {
        requested-at: block-height,
        documents-hash: documents-hash,
        status: "pending"
      }
    )
    (ok true)
  )
)

(define-public (verify-producer
  (producer principal)
  (license-number (string-ascii 50))
  (specialization (string-ascii 100))
  (location (string-ascii 100))
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set producers
      { producer: producer }
      {
        verified: true,
        verification-date: block-height,
        license-number: license-number,
        specialization: specialization,
        location: location
      }
    )
    (map-set verification-requests
      { producer: producer }
      {
        requested-at: block-height,
        documents-hash: "",
        status: "approved"
      }
    )
    (var-set total-producers (+ (var-get total-producers) u1))
    (ok true)
  )
)

(define-public (revoke-verification (producer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? producers { producer: producer })
      producer-data (begin
        (map-set producers
          { producer: producer }
          (merge producer-data { verified: false })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Read-only functions
(define-read-only (is-verified (producer principal))
  (match (map-get? producers { producer: producer })
    producer-data (get verified producer-data)
    false
  )
)

(define-read-only (get-producer-info (producer principal))
  (map-get? producers { producer: producer })
)

(define-read-only (get-verification-request (producer principal))
  (map-get? verification-requests { producer: producer })
)

(define-read-only (get-total-producers)
  (var-get total-producers)
)
