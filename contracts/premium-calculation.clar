;; Premium Calculation Contract
;; Adjusts rates based on risk factors

(define-data-var admin principal tx-sender)

;; Base premium rates by crop type
(define-map base-rates
  { crop-type: (string-ascii 64) }
  { rate: uint }
)

;; Risk factors by location
(define-map location-risk-factors
  { location-id: uint }
  { factor: uint }
)

;; Historical loss data
(define-map historical-losses
  { location-id: uint, crop-type: (string-ascii 64) }
  { loss-ratio: uint }
)

;; Initialize base rates
(define-public (set-base-rate (crop-type (string-ascii 64)) (rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set base-rates
      { crop-type: crop-type }
      { rate: rate }
    )
    (ok true)
  )
)

;; Set location risk factor
(define-public (set-location-risk-factor (location-id uint) (factor uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set location-risk-factors
      { location-id: location-id }
      { factor: factor }
    )
    (ok true)
  )
)

;; Update historical loss data
(define-public (update-historical-loss (location-id uint) (crop-type (string-ascii 64)) (loss-ratio uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set historical-losses
      { location-id: location-id, crop-type: crop-type }
      { loss-ratio: loss-ratio }
    )
    (ok true)
  )
)

;; Calculate premium for a policy
(define-read-only (calculate-premium
    (crop-type (string-ascii 64))
    (coverage-amount uint)
    (location-id uint))
  (let (
    (base-rate (default-to { rate: u1000 } (map-get? base-rates { crop-type: crop-type })))
    (risk-factor (default-to { factor: u100 } (map-get? location-risk-factors { location-id: location-id })))
    (loss-data (default-to { loss-ratio: u100 } (map-get? historical-losses { location-id: location-id, crop-type: crop-type })))
  )
    ;; Formula: (base-rate * risk-factor * loss-ratio * coverage-amount) / 1,000,000
    ;; Rates and factors are in basis points (1/100 of a percent)
    (/ (* (* (* (get rate base-rate) (get factor risk-factor)) (get loss-ratio loss-data)) coverage-amount) u1000000)
  )
)

;; Get base rate for a crop type
(define-read-only (get-base-rate (crop-type (string-ascii 64)))
  (map-get? base-rates { crop-type: crop-type })
)

;; Get risk factor for a location
(define-read-only (get-location-risk-factor (location-id uint))
  (map-get? location-risk-factors { location-id: location-id })
)

;; Get historical loss data
(define-read-only (get-historical-loss (location-id uint) (crop-type (string-ascii 64)))
  (map-get? historical-losses { location-id: location-id, crop-type: crop-type })
)

;; Set admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
