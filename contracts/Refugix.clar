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

(define-constant STATUS-PENDING u0)
(define-constant STATUS-VERIFIED u1)
(define-constant STATUS-REJECTED u2)
(define-constant STATUS-INACTIVE u3)

(define-data-var contract-owner principal tx-sender)
(define-data-var next-refugee-id uint u1)
(define-data-var next-document-id uint u1)

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
