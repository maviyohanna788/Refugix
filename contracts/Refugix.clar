;; title: Refugix
;; version: 1.0.0
;; summary: Non-custodial refugee ID registry for verified displacement records
;; description: A decentralized system for managing refugee identity and displacement verification

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-INVALID-VERIFIER (err u104))
(define-constant ERR-ALREADY-VERIFIED (err u105))
(define-constant ERR-INVALID-DOCUMENT (err u106))
(define-constant ERR-FAMILY-NOT-FOUND (err u107))
(define-constant ERR-ALREADY-CONNECTED (err u108))
(define-constant ERR-INVALID-RELATIONSHIP (err u109))
(define-constant ERR-SEARCH-NOT-FOUND (err u110))
(define-constant ERR-INVALID-SEARCH-STATUS (err u111))
(define-constant ERR-ALERT-NOT-FOUND (err u112))
(define-constant ERR-ALREADY-RESPONDED (err u113))
(define-constant ERR-INVALID-EMERGENCY-TYPE (err u114))
(define-constant ERR-INVALID-PRIORITY (err u115))
(define-constant ERR-RESPONSE-NOT-FOUND (err u116))

(define-constant STATUS-PENDING u0)
(define-constant STATUS-VERIFIED u1)
(define-constant STATUS-REJECTED u2)
(define-constant STATUS-INACTIVE u3)

(define-constant RELATIONSHIP-PARENT u0)
(define-constant RELATIONSHIP-CHILD u1)
(define-constant RELATIONSHIP-SPOUSE u2)
(define-constant RELATIONSHIP-SIBLING u3)
(define-constant RELATIONSHIP-GRANDPARENT u4)
(define-constant RELATIONSHIP-GRANDCHILD u5)
(define-constant RELATIONSHIP-OTHER u6)

(define-constant SEARCH-STATUS-ACTIVE u0)
(define-constant SEARCH-STATUS-FOUND u1)
(define-constant SEARCH-STATUS-CLOSED u2)

(define-constant EMERGENCY-MEDICAL u0)
(define-constant EMERGENCY-SECURITY u1)
(define-constant EMERGENCY-SHELTER u2)
(define-constant EMERGENCY-FOOD u3)
(define-constant EMERGENCY-WATER u4)
(define-constant EMERGENCY-TRANSPORT u5)
(define-constant EMERGENCY-OTHER u6)

(define-constant PRIORITY-LOW u0)
(define-constant PRIORITY-MEDIUM u1)
(define-constant PRIORITY-HIGH u2)
(define-constant PRIORITY-CRITICAL u3)

(define-constant ALERT-STATUS-ACTIVE u0)
(define-constant ALERT-STATUS-RESPONDING u1)
(define-constant ALERT-STATUS-RESOLVED u2)
(define-constant ALERT-STATUS-CLOSED u3)

(define-data-var contract-owner principal tx-sender)
(define-data-var next-refugee-id uint u1)
(define-data-var next-document-id uint u1)
(define-data-var next-family-id uint u1)
(define-data-var next-search-id uint u1)
(define-data-var next-alert-id uint u1)
(define-data-var next-response-id uint u1)

(define-map refugees uint {
    owner: principal,
    full-name: (string-ascii 100),
    date-of-birth: (string-ascii 10),
    nationality: (string-ascii 50),
    origin-country: (string-ascii 50),
    origin-city: (string-ascii 50),
    current-location: (string-ascii 100),
    emergency-contact: (string-ascii 100),
    phone-number: (string-ascii 20),
    displacement-reason: (string-ascii 200),
    status: uint,
    registered-at: uint,
    verified-at: (optional uint),
    verified-by: (optional principal)
})

(define-map verifiers principal {
    name: (string-ascii 100),
    organization: (string-ascii 100),
    authorized: bool,
    verified-count: uint,
    added-at: uint
})

(define-map documents uint {
    refugee-id: uint,
    document-type: (string-ascii 50),
    document-hash: (string-ascii 64),
    ipfs-hash: (string-ascii 100),
    uploaded-by: principal,
    verified: bool,
    uploaded-at: uint
})

(define-map refugee-documents uint (list 20 uint))
(define-map principal-to-refugee principal uint)

(define-map family-connections uint {
    refugee-id-1: uint,
    refugee-id-2: uint,
    relationship: uint,
    verified: bool,
    created-by: principal,
    created-at: uint,
    verified-by: (optional principal),
    verified-at: (optional uint)
})

(define-map family-searches uint {
    searcher-id: uint,
    missing-person-name: (string-ascii 100),
    missing-person-dob: (string-ascii 10),
    missing-person-nationality: (string-ascii 50),
    relationship: uint,
    last-known-location: (string-ascii 100),
    additional-info: (string-ascii 200),
    status: uint,
    created-at: uint,
    updated-at: uint
})

(define-map refugee-family-connections uint (list 10 uint))
(define-map refugee-active-searches uint (list 5 uint))

(define-map emergency-alerts uint {
    refugee-id: uint,
    emergency-type: uint,
    priority: uint,
    location: (string-ascii 100),
    description: (string-ascii 300),
    contact-info: (string-ascii 100),
    status: uint,
    created-at: uint,
    updated-at: uint,
    response-count: uint
})

(define-map alert-responses uint {
    alert-id: uint,
    responder-id: uint,
    responder-type: uint,
    response-message: (string-ascii 200),
    estimated-arrival: (optional uint),
    contact-info: (string-ascii 100),
    created-at: uint,
    status: uint
})

(define-map refugee-emergency-alerts uint (list 10 uint))
(define-map alert-response-list uint (list 20 uint))

(define-public (register-refugee 
    (full-name (string-ascii 100))
    (date-of-birth (string-ascii 10))
    (nationality (string-ascii 50))
    (origin-country (string-ascii 50))
    (origin-city (string-ascii 50))
    (current-location (string-ascii 100))
    (emergency-contact (string-ascii 100))
    (phone-number (string-ascii 20))
    (displacement-reason (string-ascii 200)))
    (let (
        (refugee-id (var-get next-refugee-id))
        (current-height stacks-block-height))
        (asserts! (is-none (map-get? principal-to-refugee tx-sender)) ERR-ALREADY-REGISTERED)
        (map-set refugees refugee-id {
            owner: tx-sender,
            full-name: full-name,
            date-of-birth: date-of-birth,
            nationality: nationality,
            origin-country: origin-country,
            origin-city: origin-city,
            current-location: current-location,
            emergency-contact: emergency-contact,
            phone-number: phone-number,
            displacement-reason: displacement-reason,
            status: STATUS-PENDING,
            registered-at: current-height,
            verified-at: none,
            verified-by: none
        })
        (map-set principal-to-refugee tx-sender refugee-id)
        (var-set next-refugee-id (+ refugee-id u1))
        (ok refugee-id)))

(define-public (update-location (new-location (string-ascii 100)))
    (let (
        (refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (refugee-data (unwrap! (map-get? refugees refugee-id) ERR-NOT-FOUND)))
        (map-set refugees refugee-id (merge refugee-data {current-location: new-location}))
        (ok true)))

(define-public (update-emergency-contact (new-contact (string-ascii 100)))
    (let (
        (refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (refugee-data (unwrap! (map-get? refugees refugee-id) ERR-NOT-FOUND)))
        (map-set refugees refugee-id (merge refugee-data {emergency-contact: new-contact}))
        (ok true)))

(define-public (add-verifier 
    (verifier principal)
    (name (string-ascii 100))
    (organization (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (map-set verifiers verifier {
            name: name,
            organization: organization,
            authorized: true,
            verified-count: u0,
            added-at: stacks-block-height
        })
        (ok true)))

(define-public (remove-verifier (verifier principal))
    (let (
        (verifier-data (unwrap! (map-get? verifiers verifier) ERR-NOT-FOUND)))
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (map-set verifiers verifier (merge verifier-data {authorized: false}))
        (ok true)))

(define-public (verify-refugee (refugee-id uint) (approve bool))
    (let (
        (refugee-data (unwrap! (map-get? refugees refugee-id) ERR-NOT-FOUND))
        (verifier-data (unwrap! (map-get? verifiers tx-sender) ERR-INVALID-VERIFIER))
        (new-status (if approve STATUS-VERIFIED STATUS-REJECTED))
        (current-height stacks-block-height))
        (asserts! (get authorized verifier-data) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status refugee-data) STATUS-PENDING) ERR-ALREADY-VERIFIED)
        (map-set refugees refugee-id (merge refugee-data {
            status: new-status,
            verified-at: (some current-height),
            verified-by: (some tx-sender)
        }))
        (if approve
            (map-set verifiers tx-sender (merge verifier-data {
                verified-count: (+ (get verified-count verifier-data) u1)
            }))
            true)
        (ok true)))

(define-public (upload-document 
    (refugee-id uint)
    (document-type (string-ascii 50))
    (document-hash (string-ascii 64))
    (ipfs-hash (string-ascii 100)))
    (let (
        (refugee-data (unwrap! (map-get? refugees refugee-id) ERR-NOT-FOUND))
        (document-id (var-get next-document-id))
        (current-docs (default-to (list) (map-get? refugee-documents refugee-id))))
        (asserts! (is-eq tx-sender (get owner refugee-data)) ERR-NOT-AUTHORIZED)
        (map-set documents document-id {
            refugee-id: refugee-id,
            document-type: document-type,
            document-hash: document-hash,
            ipfs-hash: ipfs-hash,
            uploaded-by: tx-sender,
            verified: false,
            uploaded-at: stacks-block-height
        })
        (map-set refugee-documents refugee-id (unwrap! (as-max-len? (append current-docs document-id) u20) ERR-INVALID-DOCUMENT))
        (var-set next-document-id (+ document-id u1))
        (ok document-id)))

(define-public (verify-document (document-id uint))
    (let (
        (document-data (unwrap! (map-get? documents document-id) ERR-NOT-FOUND))
        (verifier-data (unwrap! (map-get? verifiers tx-sender) ERR-INVALID-VERIFIER)))
        (asserts! (get authorized verifier-data) ERR-NOT-AUTHORIZED)
        (map-set documents document-id (merge document-data {verified: true}))
        (ok true)))

(define-public (set-refugee-status (refugee-id uint) (new-status uint))
    (let (
        (refugee-data (unwrap! (map-get? refugees refugee-id) ERR-NOT-FOUND)))
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq new-status STATUS-PENDING)
                     (is-eq new-status STATUS-VERIFIED)
                     (is-eq new-status STATUS-REJECTED)
                     (is-eq new-status STATUS-INACTIVE)) ERR-INVALID-STATUS)
        (map-set refugees refugee-id (merge refugee-data {status: new-status}))
        (ok true)))

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)))

(define-read-only (get-refugee (refugee-id uint))
    (map-get? refugees refugee-id))

(define-read-only (get-refugee-by-principal (owner principal))
    (match (map-get? principal-to-refugee owner)
        refugee-id (map-get? refugees refugee-id)
        none))

(define-read-only (get-verifier (verifier principal))
    (map-get? verifiers verifier))

(define-read-only (get-document (document-id uint))
    (map-get? documents document-id))

(define-read-only (get-refugee-documents (refugee-id uint))
    (map-get? refugee-documents refugee-id))

(define-read-only (get-contract-owner)
    (var-get contract-owner))

(define-read-only (get-next-refugee-id)
    (var-get next-refugee-id))

(define-read-only (get-next-document-id)
    (var-get next-document-id))

(define-read-only (is-refugee-verified (refugee-id uint))
    (match (map-get? refugees refugee-id)
        refugee-data (is-eq (get status refugee-data) STATUS-VERIFIED)
        false))

(define-read-only (is-verifier-authorized (verifier principal))
    (match (map-get? verifiers verifier)
        verifier-data (get authorized verifier-data)
        false))

(define-read-only (count-verified-refugees)
    (let (
        (total-refugees (- (var-get next-refugee-id) u1)))
        (fold count-verified-helper (list total-refugees) u0)))

(define-read-only (get-refugee-status (refugee-id uint))
    (match (map-get? refugees refugee-id)
        refugee-data (some (get status refugee-data))
        none))
(define-private (count-verified-helper (refugee-id uint) (count uint))
    (if (is-refugee-verified refugee-id)
        (+ count u1)
        count))

(define-public (create-family-connection 
    (other-refugee-id uint)
    (relationship uint))
    (let (
        (family-id (var-get next-family-id))
        (searcher-refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (other-refugee-data (unwrap! (map-get? refugees other-refugee-id) ERR-NOT-FOUND))
        (current-connections (default-to (list) (map-get? refugee-family-connections searcher-refugee-id)))
        (other-connections (default-to (list) (map-get? refugee-family-connections other-refugee-id)))
        (current-height stacks-block-height))
        (asserts! (not (is-eq searcher-refugee-id other-refugee-id)) ERR-INVALID-RELATIONSHIP)
        (asserts! (or (is-eq relationship RELATIONSHIP-PARENT)
                     (is-eq relationship RELATIONSHIP-CHILD)
                     (is-eq relationship RELATIONSHIP-SPOUSE)
                     (is-eq relationship RELATIONSHIP-SIBLING)
                     (is-eq relationship RELATIONSHIP-GRANDPARENT)
                     (is-eq relationship RELATIONSHIP-GRANDCHILD)
                     (is-eq relationship RELATIONSHIP-OTHER)) ERR-INVALID-RELATIONSHIP)
        (map-set family-connections family-id {
            refugee-id-1: searcher-refugee-id,
            refugee-id-2: other-refugee-id,
            relationship: relationship,
            verified: false,
            created-by: tx-sender,
            created-at: current-height,
            verified-by: none,
            verified-at: none
        })
        (map-set refugee-family-connections searcher-refugee-id 
            (unwrap! (as-max-len? (append current-connections family-id) u10) ERR-ALREADY-CONNECTED))
        (map-set refugee-family-connections other-refugee-id 
            (unwrap! (as-max-len? (append other-connections family-id) u10) ERR-ALREADY-CONNECTED))
        (var-set next-family-id (+ family-id u1))
        (ok family-id)))

(define-public (verify-family-connection (family-id uint))
    (let (
        (connection-data (unwrap! (map-get? family-connections family-id) ERR-FAMILY-NOT-FOUND))
        (verifier-data (unwrap! (map-get? verifiers tx-sender) ERR-INVALID-VERIFIER))
        (current-height stacks-block-height))
        (asserts! (get authorized verifier-data) ERR-NOT-AUTHORIZED)
        (asserts! (not (get verified connection-data)) ERR-ALREADY-VERIFIED)
        (map-set family-connections family-id (merge connection-data {
            verified: true,
            verified-by: (some tx-sender),
            verified-at: (some current-height)
        }))
        (ok true)))

(define-public (create-family-search 
    (missing-person-name (string-ascii 100))
    (missing-person-dob (string-ascii 10))
    (missing-person-nationality (string-ascii 50))
    (relationship uint)
    (last-known-location (string-ascii 100))
    (additional-info (string-ascii 200)))
    (let (
        (search-id (var-get next-search-id))
        (searcher-refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (current-searches (default-to (list) (map-get? refugee-active-searches searcher-refugee-id)))
        (current-height stacks-block-height))
        (asserts! (or (is-eq relationship RELATIONSHIP-PARENT)
                     (is-eq relationship RELATIONSHIP-CHILD)
                     (is-eq relationship RELATIONSHIP-SPOUSE)
                     (is-eq relationship RELATIONSHIP-SIBLING)
                     (is-eq relationship RELATIONSHIP-GRANDPARENT)
                     (is-eq relationship RELATIONSHIP-GRANDCHILD)
                     (is-eq relationship RELATIONSHIP-OTHER)) ERR-INVALID-RELATIONSHIP)
        (map-set family-searches search-id {
            searcher-id: searcher-refugee-id,
            missing-person-name: missing-person-name,
            missing-person-dob: missing-person-dob,
            missing-person-nationality: missing-person-nationality,
            relationship: relationship,
            last-known-location: last-known-location,
            additional-info: additional-info,
            status: SEARCH-STATUS-ACTIVE,
            created-at: current-height,
            updated-at: current-height
        })
        (map-set refugee-active-searches searcher-refugee-id 
            (unwrap! (as-max-len? (append current-searches search-id) u5) ERR-INVALID-SEARCH-STATUS))
        (var-set next-search-id (+ search-id u1))
        (ok search-id)))

(define-public (update-search-status (search-id uint) (new-status uint))
    (let (
        (search-data (unwrap! (map-get? family-searches search-id) ERR-SEARCH-NOT-FOUND))
        (searcher-refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (current-height stacks-block-height))
        (asserts! (is-eq searcher-refugee-id (get searcher-id search-data)) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq new-status SEARCH-STATUS-ACTIVE)
                     (is-eq new-status SEARCH-STATUS-FOUND)
                     (is-eq new-status SEARCH-STATUS-CLOSED)) ERR-INVALID-SEARCH-STATUS)
        (map-set family-searches search-id (merge search-data {
            status: new-status,
            updated-at: current-height
        }))
        (ok true)))

(define-public (suggest-family-match (search-id uint) (potential-refugee-id uint))
    (let (
        (search-data (unwrap! (map-get? family-searches search-id) ERR-SEARCH-NOT-FOUND))
        (potential-refugee-data (unwrap! (map-get? refugees potential-refugee-id) ERR-NOT-FOUND))
        (verifier-data (unwrap! (map-get? verifiers tx-sender) ERR-INVALID-VERIFIER)))
        (asserts! (get authorized verifier-data) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status search-data) SEARCH-STATUS-ACTIVE) ERR-INVALID-SEARCH-STATUS)
        (ok {
            search-id: search-id,
            suggested-refugee-id: potential-refugee-id,
            match-score: (calculate-match-score search-data potential-refugee-data)
        })))

(define-private (calculate-match-score 
    (search-data {searcher-id: uint, missing-person-name: (string-ascii 100), missing-person-dob: (string-ascii 10), missing-person-nationality: (string-ascii 50), relationship: uint, last-known-location: (string-ascii 100), additional-info: (string-ascii 200), status: uint, created-at: uint, updated-at: uint})
    (refugee-data {owner: principal, full-name: (string-ascii 100), date-of-birth: (string-ascii 10), nationality: (string-ascii 50), origin-country: (string-ascii 50), origin-city: (string-ascii 50), current-location: (string-ascii 100), emergency-contact: (string-ascii 100), phone-number: (string-ascii 20), displacement-reason: (string-ascii 200), status: uint, registered-at: uint, verified-at: (optional uint), verified-by: (optional principal)}))
    (let (
        (name-match (if (is-eq (get missing-person-name search-data) (get full-name refugee-data)) u30 u0))
        (dob-match (if (is-eq (get missing-person-dob search-data) (get date-of-birth refugee-data)) u40 u0))
        (nationality-match (if (is-eq (get missing-person-nationality search-data) (get nationality refugee-data)) u30 u0)))
        (+ name-match dob-match nationality-match)))

(define-read-only (get-family-connection (family-id uint))
    (map-get? family-connections family-id))

(define-read-only (get-family-search (search-id uint))
    (map-get? family-searches search-id))

(define-read-only (get-refugee-family-connections (refugee-id uint))
    (map-get? refugee-family-connections refugee-id))

(define-read-only (get-refugee-active-searches (refugee-id uint))
    (map-get? refugee-active-searches refugee-id))

(define-read-only (get-next-family-id)
    (var-get next-family-id))

(define-read-only (get-next-search-id)
    (var-get next-search-id))

(define-read-only (is-family-connection-verified (family-id uint))
    (match (map-get? family-connections family-id)
        connection-data (get verified connection-data)
        false))

(define-read-only (search-refugees-by-criteria 
    (search-name (string-ascii 100))
    (search-dob (string-ascii 10))
    (search-nationality (string-ascii 50)))
    (let ((fixed-list (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)))
        (fold search-refugees-helper fixed-list (list))))

(define-private (search-refugees-helper (refugee-id uint) (matches (list 50 uint)))
    (match (map-get? refugees refugee-id)
        refugee-data 
            (if (and (is-eq (get full-name refugee-data) (unwrap-panic (element-at? (list "name") u0)))
                    (is-eq (get date-of-birth refugee-data) (unwrap-panic (element-at? (list "dob") u0)))
                    (is-eq (get nationality refugee-data) (unwrap-panic (element-at? (list "nationality") u0))))
                (unwrap-panic (as-max-len? (append matches refugee-id) u50))
                matches)
        matches))

(define-read-only (count-active-searches)
    (let ((fixed-list (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)))
        (fold count-active-searches-helper fixed-list u0)))

(define-private (count-active-searches-helper (search-id uint) (count uint))
    (match (map-get? family-searches search-id)
        search-data 
            (if (is-eq (get status search-data) SEARCH-STATUS-ACTIVE)
                (+ count u1)
                count)
        count))

(define-public (create-emergency-alert 
    (emergency-type uint)
    (priority uint)
    (location (string-ascii 100))
    (description (string-ascii 300))
    (contact-info (string-ascii 100)))
    (let (
        (alert-id (var-get next-alert-id))
        (refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (current-alerts (default-to (list) (map-get? refugee-emergency-alerts refugee-id)))
        (current-height stacks-block-height))
        (asserts! (or (is-eq emergency-type EMERGENCY-MEDICAL)
                     (is-eq emergency-type EMERGENCY-SECURITY)
                     (is-eq emergency-type EMERGENCY-SHELTER)
                     (is-eq emergency-type EMERGENCY-FOOD)
                     (is-eq emergency-type EMERGENCY-WATER)
                     (is-eq emergency-type EMERGENCY-TRANSPORT)
                     (is-eq emergency-type EMERGENCY-OTHER)) ERR-INVALID-EMERGENCY-TYPE)
        (asserts! (or (is-eq priority PRIORITY-LOW)
                     (is-eq priority PRIORITY-MEDIUM)
                     (is-eq priority PRIORITY-HIGH)
                     (is-eq priority PRIORITY-CRITICAL)) ERR-INVALID-PRIORITY)
        (map-set emergency-alerts alert-id {
            refugee-id: refugee-id,
            emergency-type: emergency-type,
            priority: priority,
            location: location,
            description: description,
            contact-info: contact-info,
            status: ALERT-STATUS-ACTIVE,
            created-at: current-height,
            updated-at: current-height,
            response-count: u0
        })
        (map-set refugee-emergency-alerts refugee-id 
            (unwrap! (as-max-len? (append current-alerts alert-id) u10) ERR-ALERT-NOT-FOUND))
        (map-set alert-response-list alert-id (list))
        (var-set next-alert-id (+ alert-id u1))
        (ok alert-id)))

(define-public (respond-to-alert 
    (alert-id uint)
    (responder-type uint)
    (response-message (string-ascii 200))
    (estimated-arrival (optional uint))
    (contact-info (string-ascii 100)))
    (let (
        (response-id (var-get next-response-id))
        (alert-data (unwrap! (map-get? emergency-alerts alert-id) ERR-ALERT-NOT-FOUND))
        (responder-refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (current-responses (default-to (list) (map-get? alert-response-list alert-id)))
        (current-height stacks-block-height))
        (asserts! (is-eq (get status alert-data) ALERT-STATUS-ACTIVE) ERR-INVALID-STATUS)
        (map-set alert-responses response-id {
            alert-id: alert-id,
            responder-id: responder-refugee-id,
            responder-type: responder-type,
            response-message: response-message,
            estimated-arrival: estimated-arrival,
            contact-info: contact-info,
            created-at: current-height,
            status: ALERT-STATUS-ACTIVE
        })
        (map-set alert-response-list alert-id 
            (unwrap! (as-max-len? (append current-responses response-id) u20) ERR-ALREADY-RESPONDED))
        (map-set emergency-alerts alert-id (merge alert-data {
            response-count: (+ (get response-count alert-data) u1),
            status: ALERT-STATUS-RESPONDING,
            updated-at: current-height
        }))
        (var-set next-response-id (+ response-id u1))
        (ok response-id)))

(define-public (update-alert-status (alert-id uint) (new-status uint))
    (let (
        (alert-data (unwrap! (map-get? emergency-alerts alert-id) ERR-ALERT-NOT-FOUND))
        (refugee-id (unwrap! (map-get? principal-to-refugee tx-sender) ERR-NOT-FOUND))
        (current-height stacks-block-height))
        (asserts! (is-eq refugee-id (get refugee-id alert-data)) ERR-NOT-AUTHORIZED)
        (asserts! (or (is-eq new-status ALERT-STATUS-ACTIVE)
                     (is-eq new-status ALERT-STATUS-RESPONDING)
                     (is-eq new-status ALERT-STATUS-RESOLVED)
                     (is-eq new-status ALERT-STATUS-CLOSED)) ERR-INVALID-STATUS)
        (map-set emergency-alerts alert-id (merge alert-data {
            status: new-status,
            updated-at: current-height
        }))
        (ok true)))

(define-public (close-expired-alerts-batch (alert-ids (list 10 uint)))
    (let (
        (verifier-data (unwrap! (map-get? verifiers tx-sender) ERR-INVALID-VERIFIER))
        (current-height stacks-block-height))
        (asserts! (get authorized verifier-data) ERR-NOT-AUTHORIZED)
        (fold close-single-alert alert-ids u0)
        (ok true)))

(define-private (close-single-alert (alert-id uint) (processed uint))
    (let (
        (alert-data (default-to 
            {refugee-id: u0, emergency-type: u0, priority: u0, location: "", description: "", 
             contact-info: "", status: u0, created-at: u0, updated-at: u0, response-count: u0}
            (map-get? emergency-alerts alert-id)))
        (current-height stacks-block-height)
        (alert-age (- current-height (get created-at alert-data))))
        (if (and (> alert-age u144) (is-eq (get status alert-data) ALERT-STATUS-ACTIVE))
            (begin
                (map-set emergency-alerts alert-id (merge alert-data {
                    status: ALERT-STATUS-CLOSED,
                    updated-at: current-height
                }))
                (+ processed u1))
            processed)))

(define-read-only (get-emergency-alert (alert-id uint))
    (map-get? emergency-alerts alert-id))

(define-read-only (get-alert-response (response-id uint))
    (map-get? alert-responses response-id))

(define-read-only (get-refugee-emergency-alerts (refugee-id uint))
    (map-get? refugee-emergency-alerts refugee-id))

(define-read-only (get-alert-responses (alert-id uint))
    (map-get? alert-response-list alert-id))

(define-read-only (get-next-alert-id)
    (var-get next-alert-id))

(define-read-only (get-next-response-id)
    (var-get next-response-id))

(define-read-only (is-alert-active (alert-id uint))
    (match (map-get? emergency-alerts alert-id)
        alert-data (is-eq (get status alert-data) ALERT-STATUS-ACTIVE)
        false))

(define-read-only (get-high-priority-alerts)
    (let ((fixed-list (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)))
        (fold get-high-priority-helper fixed-list (list))))

(define-private (get-high-priority-helper (alert-id uint) (matches (list 50 uint)))
    (match (map-get? emergency-alerts alert-id)
        alert-data 
            (if (and (is-eq (get status alert-data) ALERT-STATUS-ACTIVE)
                    (or (is-eq (get priority alert-data) PRIORITY-HIGH)
                        (is-eq (get priority alert-data) PRIORITY-CRITICAL)))
                (unwrap-panic (as-max-len? (append matches alert-id) u50))
                matches)
        matches))

(define-read-only (count-active-alerts)
    (let ((fixed-list (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)))
        (fold count-active-alerts-helper fixed-list u0)))

(define-private (count-active-alerts-helper (alert-id uint) (count uint))
    (match (map-get? emergency-alerts alert-id)
        alert-data 
            (if (is-eq (get status alert-data) ALERT-STATUS-ACTIVE)
                (+ count u1)
                count)
        count))

(define-read-only (get-medical-alerts)
    (let ((fixed-list (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)))
        (fold get-medical-alerts-helper fixed-list (list))))

(define-private (get-medical-alerts-helper (alert-id uint) (matches (list 50 uint)))
    (match (map-get? emergency-alerts alert-id)
        alert-data 
            (if (and (is-eq (get status alert-data) ALERT-STATUS-ACTIVE)
                    (is-eq (get emergency-type alert-data) EMERGENCY-MEDICAL))
                (unwrap-panic (as-max-len? (append matches alert-id) u50))
                matches)
        matches))

(define-read-only (get-alert-statistics)
    (let ((fixed-list (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)))
        (fold calculate-alert-stats fixed-list 
            {total: u0, active: u0, resolved: u0, critical: u0})))

(define-private (calculate-alert-stats (alert-id uint) (stats {total: uint, active: uint, resolved: uint, critical: uint}))
    (match (map-get? emergency-alerts alert-id)
        alert-data 
            {total: (+ (get total stats) u1),
             active: (+ (get active stats) (if (is-eq (get status alert-data) ALERT-STATUS-ACTIVE) u1 u0)),
             resolved: (+ (get resolved stats) (if (is-eq (get status alert-data) ALERT-STATUS-RESOLVED) u1 u0)),
             critical: (+ (get critical stats) (if (is-eq (get priority alert-data) PRIORITY-CRITICAL) u1 u0))}
        stats))




