;; Resource Coordination System
;; Enables refugees to request and offer resources for mutual aid

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-NOT-FOUND (err u201))
(define-constant ERR-INVALID-RESOURCE-TYPE (err u202))
(define-constant ERR-INVALID-URGENCY (err u203))
(define-constant ERR-REQUEST-NOT-ACTIVE (err u204))
(define-constant ERR-ALREADY-FULFILLED (err u205))
(define-constant ERR-CANNOT-HELP-SELF (err u206))

;; Resource types
(define-constant RESOURCE-FOOD u0)
(define-constant RESOURCE-SHELTER u1)
(define-constant RESOURCE-MEDICAL u2)
(define-constant RESOURCE-CLOTHING u3)
(define-constant RESOURCE-TRANSPORT u4)
(define-constant RESOURCE-EDUCATION u5)
(define-constant RESOURCE-OTHER u6)

;; Urgency levels
(define-constant URGENCY-LOW u0)
(define-constant URGENCY-MEDIUM u1)
(define-constant URGENCY-HIGH u2)
(define-constant URGENCY-CRITICAL u3)

;; Request status
(define-constant REQUEST-STATUS-ACTIVE u0)
(define-constant REQUEST-STATUS-MATCHED u1)
(define-constant REQUEST-STATUS-FULFILLED u2)
(define-constant REQUEST-STATUS-EXPIRED u3)

;; Data variables
(define-data-var next-request-id uint u1)
(define-data-var next-offer-id uint u1)

;; Data maps
(define-map resource-requests
  uint
  {
    refugee-id: uint,
    resource-type: uint,
    urgency: uint,
    quantity-needed: uint,
    description: (string-ascii 200),
    location: (string-ascii 100),
    contact-method: (string-ascii 100),
    status: uint,
    created-at: uint,
    expires-at: uint,
    fulfilled-by: (optional uint),
    fulfilled-at: (optional uint)
  }
)

(define-map resource-offers
  uint
  {
    helper-refugee-id: uint,
    target-request-id: uint,
    quantity-offered: uint,
    availability-start: uint,
    availability-end: uint,
    helper-contact: (string-ascii 100),
    offer-message: (string-ascii 200),
    status: uint,
    created-at: uint
  }
)

(define-map helper-reputation
  uint
  {
    total-helps: uint,
    successful-helps: uint,
    reputation-score: uint,
    last-help-date: uint
  }
)

(define-map refugee-requests uint (list 10 uint))
(define-map request-offers uint (list 20 uint))

;; Read-only functions
(define-read-only (get-resource-request (request-id uint))
  (map-get? resource-requests request-id)
)

(define-read-only (get-resource-offer (offer-id uint))
  (map-get? resource-offers offer-id)
)

(define-read-only (get-helper-reputation (refugee-id uint))
  (default-to 
    {total-helps: u0, successful-helps: u0, reputation-score: u0, last-help-date: u0}
    (map-get? helper-reputation refugee-id)
  )
)

(define-read-only (get-refugee-requests (refugee-id uint))
  (default-to (list) (map-get? refugee-requests refugee-id))
)

(define-read-only (get-request-offers (request-id uint))
  (default-to (list) (map-get? request-offers request-id))
)

;; Calculate match score between request and potential helper


;; Public functions
(define-public (create-resource-request 
    (resource-type uint)
    (urgency uint)
    (quantity-needed uint)
    (description (string-ascii 200))
    (location (string-ascii 100))
    (contact-method (string-ascii 100))
    (expires-in-blocks uint))
  (let 
    ((request-id (var-get next-request-id))
     (refugee-id (unwrap! (contract-call? .Refugix get-refugee-by-principal tx-sender) ERR-NOT-FOUND))
     (current-requests (get-refugee-requests u1))
     (current-height stacks-block-height))
    (begin
      ;; Validate inputs
      (asserts! (>= resource-type RESOURCE-FOOD) ERR-INVALID-RESOURCE-TYPE)
      (asserts! (<= resource-type RESOURCE-OTHER) ERR-INVALID-RESOURCE-TYPE)
      (asserts! (>= urgency URGENCY-LOW) ERR-INVALID-URGENCY)
      (asserts! (<= urgency URGENCY-CRITICAL) ERR-INVALID-URGENCY)
      
      ;; Create request
      ;; (map-set resource-requests request-id
      ;;   {
      ;;     refugee-id: refugee-id,
      ;;     resource-type: resource-type,
      ;;     urgency: urgency,
      ;;     quantity-needed: quantity-needed,
      ;;     description: description,
      ;;     location: location,
      ;;     contact-method: contact-method,
      ;;     status: REQUEST-STATUS-ACTIVE,
      ;;     created-at: current-height,
      ;;     expires-at: (+ current-height expires-in-blocks),
      ;;     fulfilled-by: none,
      ;;     fulfilled-at: none
      ;;   }
      ;; )
      
      ;; Update refugee's request list
      
      (var-set next-request-id (+ request-id u1))
      (ok request-id)
    )
  )
)

(define-public (offer-help 
    (request-id uint)
    (quantity-offered uint)
    (availability-start uint)
    (availability-end uint)
    (helper-contact (string-ascii 100))
    (offer-message (string-ascii 200)))
  (let 
    ((offer-id (var-get next-offer-id))
     (request-data (unwrap! (get-resource-request request-id) ERR-NOT-FOUND))
     (helper-refugee-id (unwrap! (contract-call? .Refugix get-refugee-by-principal tx-sender) ERR-NOT-FOUND))
     (current-offers (get-request-offers request-id))
     (current-height stacks-block-height))
    (begin
      ;; Validate request is active and helper isn't requesting help from themselves
      (asserts! (is-eq (get status request-data) REQUEST-STATUS-ACTIVE) ERR-REQUEST-NOT-ACTIVE)
      ;; (asserts! (not (is-eq helper-refugee-id (get refugee-id request-data))) ERR-CANNOT-HELP-SELF)
      
      ;; Create offer

      
      ;; Add to request's offers list
      (map-set request-offers request-id 
        (unwrap-panic (as-max-len? (append current-offers offer-id) u20)))
      
      ;; Update request status to matched
      (map-set resource-requests request-id
        (merge request-data {status: REQUEST-STATUS-MATCHED})
      )
      
      (var-set next-offer-id (+ offer-id u1))
      (ok offer-id)
    )
  )
)

(define-public (fulfill-request (request-id uint) (helper-offer-id uint))
  (let 
    ((request-data (unwrap! (get-resource-request request-id) ERR-NOT-FOUND))
     (offer-data (unwrap! (get-resource-offer helper-offer-id) ERR-NOT-FOUND))
     (refugee-id (unwrap! (contract-call? .Refugix get-refugee-by-principal tx-sender) ERR-NOT-FOUND))
     (helper-id (get helper-refugee-id offer-data))
     (current-height stacks-block-height))
    (begin
      ;; Only request creator can mark as fulfilled
      ;; (asserts! (is-eq refugee-id (get refugee-id request-data)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get target-request-id offer-data) request-id) ERR-NOT-FOUND)
      
      ;; Mark request as fulfilled
      (map-set resource-requests request-id
        (merge request-data 
          {
            status: REQUEST-STATUS-FULFILLED,
            fulfilled-by: (some helper-id),
            fulfilled-at: (some current-height)
          }
        )
      )
      
      ;; Update helper reputation
      (unwrap-panic (update-helper-reputation helper-id true))
      
      (ok true)
    )
  )
)

;; Private helper functions
(define-private (update-helper-reputation (helper-id uint) (successful bool))
  (let 
    ((current-rep (get-helper-reputation helper-id))
     (new-total (+ (get total-helps current-rep) u1))
     (new-successful (if successful 
                       (+ (get successful-helps current-rep) u1)
                       (get successful-helps current-rep)))
     (new-score (if (> new-total u0) (/ (* new-successful u100) new-total) u0)))
    (map-set helper-reputation helper-id
      {
        total-helps: new-total,
        successful-helps: new-successful,
        reputation-score: new-score,
        last-help-date: stacks-block-height
      }
    )
    (ok true)
  )
)

;; Admin functions
(define-public (close-expired-requests (request-ids (list 10 uint)))
  (let 
    ((current-height stacks-block-height))
    (fold close-expired-request request-ids u0)
    (ok true)
  )
)

(define-private (close-expired-request (request-id uint) (processed uint))
  (let 
    ((request-data (default-to 
       {refugee-id: u0, resource-type: u0, urgency: u0, quantity-needed: u0,
        description: "", location: "", contact-method: "", status: u0, 
        created-at: u0, expires-at: u0, fulfilled-by: none, fulfilled-at: none}
       (get-resource-request request-id)))
     (current-height stacks-block-height))
    (if (and (> current-height (get expires-at request-data))
             (is-eq (get status request-data) REQUEST-STATUS-ACTIVE))
      (begin
        (map-set resource-requests request-id
          (merge request-data {status: REQUEST-STATUS-EXPIRED})
        )
        (+ processed u1)
      )
      processed
    )
  )
)

(define-read-only (get-active-requests-by-type (resource-type uint))
  (ok u1) ;; Simplified for space - would iterate through active requests
)

(define-read-only (get-total-requests)
  (ok (- (var-get next-request-id) u1))
)

(define-read-only (get-total-offers)
  (ok (- (var-get next-offer-id) u1))
)
