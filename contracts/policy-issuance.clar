;; Policy Issuance Contract
;; Manages insurance terms for different crops

(define-data-var admin principal tx-sender)

;; Policy data structure
(define-map policies
  { policy-id: uint }
  {
    owner: principal,
    crop-type: (string-ascii 64),
    coverage-amount: uint,
    premium-amount: uint,
    start-date: uint,
    end-date: uint,
    location-id: uint,
    active: bool
  }
)

;; Counter for policy IDs
(define-data-var policy-counter uint u0)

;; Get the next policy ID
(define-private (get-next-policy-id)
  (begin
    (var-set policy-counter (+ (var-get policy-counter) u1))
    (var-get policy-counter)
  )
)

;; Create a new policy
(define-public (create-policy
    (crop-type (string-ascii 64))
    (coverage-amount uint)
    (premium-amount uint)
    (start-date uint)
    (end-date uint)
    (location-id uint))
  (let ((policy-id (get-next-policy-id)))
    (map-insert policies
      { policy-id: policy-id }
      {
        owner: tx-sender,
        crop-type: crop-type,
        coverage-amount: coverage-amount,
        premium-amount: premium-amount,
        start-date: start-date,
        end-date: end-date,
        location-id: location-id,
        active: true
      }
    )
    (ok policy-id)
  )
)

;; Get policy details
(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

;; Deactivate a policy
(define-public (deactivate-policy (policy-id uint))
  (let ((policy (unwrap! (map-get? policies { policy-id: policy-id }) (err u404))))
    (asserts! (is-eq tx-sender (get owner policy)) (err u403))
    (map-set policies
      { policy-id: policy-id }
      (merge policy { active: false })
    )
    (ok true)
  )
)

;; Update admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
