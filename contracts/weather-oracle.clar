;; Weather Data Oracle Contract
;; Provides verified climate information

(define-data-var admin principal tx-sender)
(define-data-var oracle-address principal tx-sender)

;; Weather data structure
(define-map weather-data
  { location-id: uint, timestamp: uint }
  {
    temperature: int,
    rainfall: uint,
    humidity: uint,
    wind-speed: uint
  }
)

;; Weather events structure
(define-map weather-events
  { event-id: uint }
  {
    location-id: uint,
    event-type: (string-ascii 64),
    severity: uint,
    timestamp: uint,
    verified: bool
  }
)

;; Counter for event IDs
(define-data-var event-counter uint u0)

;; Get the next event ID
(define-private (get-next-event-id)
  (begin
    (var-set event-counter (+ (var-get event-counter) u1))
    (var-get event-counter)
  )
)

;; Submit weather data (only oracle can do this)
(define-public (submit-weather-data
    (location-id uint)
    (timestamp uint)
    (temperature int)
    (rainfall uint)
    (humidity uint)
    (wind-speed uint))
  (begin
    (asserts! (is-eq tx-sender (var-get oracle-address)) (err u403))
    (map-set weather-data
      { location-id: location-id, timestamp: timestamp }
      {
        temperature: temperature,
        rainfall: rainfall,
        humidity: humidity,
        wind-speed: wind-speed
      }
    )
    (ok true)
  )
)

;; Report a weather event
(define-public (report-weather-event
    (location-id uint)
    (event-type (string-ascii 64))
    (severity uint)
    (timestamp uint))
  (begin
    (asserts! (is-eq tx-sender (var-get oracle-address)) (err u403))
    (let ((event-id (get-next-event-id)))
      (map-set weather-events
        { event-id: event-id }
        {
          location-id: location-id,
          event-type: event-type,
          severity: severity,
          timestamp: timestamp,
          verified: true
        }
      )
      (ok event-id)
    )
  )
)

;; Get weather data
(define-read-only (get-weather-data (location-id uint) (timestamp uint))
  (map-get? weather-data { location-id: location-id, timestamp: timestamp })
)

;; Get weather event
(define-read-only (get-weather-event (event-id uint))
  (map-get? weather-events { event-id: event-id })
)

;; Set oracle address
(define-public (set-oracle-address (new-oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set oracle-address new-oracle)
    (ok true)
  )
)

;; Set admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
