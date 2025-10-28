(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-signed (err u103))
(define-constant err-petition-closed (err u104))
(define-constant err-invalid-threshold (err u105))
(define-constant err-insufficient-signatures (err u106))
(define-constant err-petition-active (err u107))

(define-data-var petition-nonce uint u0)

(define-map petitions
    { petition-id: uint }
    {
        creator: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        target-signatures: uint,
        created-at: uint,
        deadline: uint,
        is-active: bool,
        signature-count: uint,
        is-verified: bool
    }
)

(define-map petition-signatures
    { petition-id: uint, signer: principal }
    {
        signed-at: uint,
        signature-hash: (buff 32)
    }
)

(define-map signer-petitions
    { signer: principal }
    { petition-ids: (list 100 uint) }
)

(define-map petition-signers
    { petition-id: uint }
    { signers: (list 1000 principal) }
)

(define-private (is-petition-owner (petition-id uint) (user principal))
    (match (map-get? petitions { petition-id: petition-id })
        petition-data (is-eq (get creator petition-data) user)
        false
    )
)

(define-private (is-petition-active (petition-id uint))
    (match (map-get? petitions { petition-id: petition-id })
        petition-data 
        (and 
            (get is-active petition-data)
            (< (get created-at petition-data) (get deadline petition-data))
            (< stacks-block-height (get deadline petition-data))
        )
        false
    )
)

(define-private (has-already-signed (petition-id uint) (signer principal))
    (is-some (map-get? petition-signatures { petition-id: petition-id, signer: signer }))
)

(define-private (add-signer-to-petition (petition-id uint) (signer principal))
    (let 
        (
            (current-signers (default-to (list) (get signers (map-get? petition-signers { petition-id: petition-id }))))
        )
        (map-set petition-signers 
            { petition-id: petition-id }
            { signers: (unwrap! (as-max-len? (append current-signers signer) u1000) (err u999)) }
        )
        (ok true)
    )
)

(define-private (add-petition-to-signer (signer principal) (petition-id uint))
    (let 
        (
            (current-petitions (default-to (list) (get petition-ids (map-get? signer-petitions { signer: signer }))))
        )
        (map-set signer-petitions 
            { signer: signer }
            { petition-ids: (unwrap! (as-max-len? (append current-petitions petition-id) u100) (err u999)) }
        )
        (ok true)
    )
)

(define-public (create-petition (title (string-ascii 100)) (description (string-ascii 500)) (target-signatures uint) (deadline uint))
    (let 
        (
            (petition-id (+ (var-get petition-nonce) u1))
        )
        (asserts! (> target-signatures u0) err-invalid-threshold)
        (asserts! (> deadline stacks-block-height) err-invalid-threshold)
        
        (map-set petitions
            { petition-id: petition-id }
            {
                creator: tx-sender,
                title: title,
                description: description,
                target-signatures: target-signatures,
                created-at: stacks-block-height,
                deadline: deadline,
                is-active: true,
                signature-count: u0,
                is-verified: false
            }
        )
        
        (var-set petition-nonce petition-id)
        (ok petition-id)
    )
)

(define-public (sign-petition (petition-id uint) (signature-hash (buff 32)))
    (let 
        (
            (petition-data (unwrap! (map-get? petitions { petition-id: petition-id }) err-not-found))
            (current-count (get signature-count petition-data))
        )
        (asserts! (is-petition-active petition-id) err-petition-closed)
        (asserts! (not (has-already-signed petition-id tx-sender)) err-already-signed)
        
        (map-set petition-signatures
            { petition-id: petition-id, signer: tx-sender }
            {
                signed-at: stacks-block-height,
                signature-hash: signature-hash
            }
        )
        
        (try! (add-signer-to-petition petition-id tx-sender))
        (try! (add-petition-to-signer tx-sender petition-id))
        
        (map-set petitions
            { petition-id: petition-id }
            (merge petition-data { signature-count: (+ current-count u1) })
        )
        
        (ok true)
    )
)

(define-public (verify-petition (petition-id uint))
    (let 
        (
            (petition-data (unwrap! (map-get? petitions { petition-id: petition-id }) err-not-found))
        )
        (asserts! (or (is-eq tx-sender contract-owner) (is-petition-owner petition-id tx-sender)) err-unauthorized)
        (asserts! (>= (get signature-count petition-data) (get target-signatures petition-data)) err-insufficient-signatures)
        
        (map-set petitions
            { petition-id: petition-id }
            (merge petition-data { is-verified: true })
        )
        
        (ok true)
    )
)

(define-public (close-petition (petition-id uint))
    (let 
        (
            (petition-data (unwrap! (map-get? petitions { petition-id: petition-id }) err-not-found))
        )
        (asserts! (or (is-eq tx-sender contract-owner) (is-petition-owner petition-id tx-sender)) err-unauthorized)
        (asserts! (get is-active petition-data) err-petition-closed)
        
        (map-set petitions
            { petition-id: petition-id }
            (merge petition-data { is-active: false })
        )
        
        (ok true)
    )
)

(define-public (reopen-petition (petition-id uint) (new-deadline uint))
    (let 
        (
            (petition-data (unwrap! (map-get? petitions { petition-id: petition-id }) err-not-found))
        )
        (asserts! (or (is-eq tx-sender contract-owner) (is-petition-owner petition-id tx-sender)) err-unauthorized)
        (asserts! (not (get is-active petition-data)) err-petition-active)
        (asserts! (> new-deadline stacks-block-height) err-invalid-threshold)
        
        (map-set petitions
            { petition-id: petition-id }
            (merge petition-data { is-active: true, deadline: new-deadline })
        )
        
        (ok true)
    )
)

(define-read-only (get-petition (petition-id uint))
    (map-get? petitions { petition-id: petition-id })
)

(define-read-only (get-petition-signature (petition-id uint) (signer principal))
    (map-get? petition-signatures { petition-id: petition-id, signer: signer })
)

(define-read-only (get-signer-petitions (signer principal))
    (map-get? signer-petitions { signer: signer })
)

(define-read-only (get-petition-signers (petition-id uint))
    (map-get? petition-signers { petition-id: petition-id })
)

(define-read-only (get-petition-status (petition-id uint))
    (match (map-get? petitions { petition-id: petition-id })
        petition-data 
        (ok {
            signature-count: (get signature-count petition-data),
            target-signatures: (get target-signatures petition-data),
            is-active: (get is-active petition-data),
            is-verified: (get is-verified petition-data),
            deadline-reached: (>= stacks-block-height (get deadline petition-data)),
            target-reached: (>= (get signature-count petition-data) (get target-signatures petition-data))
        })
        err-not-found
    )
)

(define-read-only (is-signature-valid (petition-id uint) (signer principal) (expected-hash (buff 32)))
    (match (map-get? petition-signatures { petition-id: petition-id, signer: signer })
        signature-data (is-eq (get signature-hash signature-data) expected-hash)
        false
    )
)

(define-read-only (get-total-petitions)
    (var-get petition-nonce)
)

(define-read-only (can-sign-petition (petition-id uint) (signer principal))
    (and 
        (is-petition-active petition-id)
        (not (has-already-signed petition-id signer))
    )
)

(define-read-only (get-petition-progress (petition-id uint))
    (match (map-get? petitions { petition-id: petition-id })
        petition-data 
        (ok {
            current: (get signature-count petition-data),
            target: (get target-signatures petition-data),
            percentage: (if (> (get target-signatures petition-data) u0)
                (/ (* (get signature-count petition-data) u100) (get target-signatures petition-data))
                u0
            )
        })
        err-not-found
    )
)

