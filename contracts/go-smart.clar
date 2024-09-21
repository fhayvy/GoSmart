;; Smart Contract Insurance

;; Define error constants with more specific messages
(define-constant ERR_INVALID_AMOUNT (err u100))
(define-constant ERR_INSUFFICIENT_FUNDS (err u101))
(define-constant ERR_CLAIM_NOT_FOUND (err u102))
(define-constant ERR_UNAUTHORIZED (err u103))
(define-constant ERR_ALREADY_INSURED (err u104))
(define-constant ERR_INVALID_PRINCIPAL (err u105))
(define-constant ERR_NOT_INSURED (err u106))
(define-constant ERR_ZERO_AMOUNT (err u107))
(define-constant ERR_CLAIM_ALREADY_PROCESSED (err u108))
(define-constant ERR_POOL_EMPTY (err u109))
(define-constant ERR_CLAIM_NOT_EXPIRED (err u110))

;; Define the contract
(define-data-var insurance-pool uint u0)
(define-data-var contract-owner principal tx-sender)
(define-map insured-contracts principal uint)
(define-map claims { claimant: principal, amount: uint } { status: (string-ascii 20), timestamp: uint, paid-amount: uint })

;; Define the claim expiration period (e.g., 30 days in blocks, assuming 10-minute block times)
(define-constant CLAIM_EXPIRATION_PERIOD u4320)

;; Function to purchase insurance
(define-public (purchase-insurance (amount uint))
  (let ((caller tx-sender))
    (asserts! (> amount u0) ERR_ZERO_AMOUNT)
    (asserts! (is-none (map-get? insured-contracts caller)) ERR_ALREADY_INSURED)
    (match (stx-transfer? amount caller (as-contract tx-sender))
      success (begin
        (var-set insurance-pool (+ (var-get insurance-pool) amount))
        (map-set insured-contracts caller amount)
        (print { event: "insurance-purchased", insured-amount: amount, buyer: caller })
        (ok true))
      error (err error))))

;; Function to file a claim
(define-public (file-claim (claim-amount uint))
  (let (
    (caller tx-sender)
    (insured-amount (default-to u0 (map-get? insured-contracts caller)))
  )
    (asserts! (> claim-amount u0) ERR_ZERO_AMOUNT)
    (asserts! (is-some (map-get? insured-contracts caller)) ERR_NOT_INSURED)
    (asserts! (>= insured-amount claim-amount) ERR_INSUFFICIENT_FUNDS)
    (asserts! (is-none (map-get? claims { claimant: caller, amount: claim-amount })) ERR_CLAIM_ALREADY_PROCESSED)
    (map-set claims { claimant: caller, amount: claim-amount } { status: "pending", timestamp: block-height, paid-amount: u0 })
    (print { event: "claim-filed", claimant: caller, claim-amount: claim-amount, timestamp: block-height })
    (ok true)))

;; Helper function to calculate payout amount
(define-private (calculate-payout-amount (claim-amount uint) (pool-balance uint))
  (if (>= pool-balance claim-amount)
      claim-amount
      pool-balance))

;; Function to approve and pay out a claim
(define-public (approve-claim (claimant principal) (claim-amount uint))
  (let (
    (claim-key { claimant: claimant, amount: claim-amount })
    (claim-data (unwrap! (map-get? claims claim-key) ERR_CLAIM_NOT_FOUND))
    (pool-balance (var-get insurance-pool))
    (payout-amount (calculate-payout-amount claim-amount pool-balance))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status claim-data) "pending") ERR_CLAIM_ALREADY_PROCESSED)
    (asserts! (> pool-balance u0) ERR_POOL_EMPTY)
    (asserts! (is-some (map-get? insured-contracts claimant)) ERR_NOT_INSURED)
    (asserts! (< (- block-height (get timestamp claim-data)) CLAIM_EXPIRATION_PERIOD) ERR_CLAIM_NOT_EXPIRED)
    (match (as-contract (stx-transfer? payout-amount tx-sender claimant))
      success (begin
        (var-set insurance-pool (- pool-balance payout-amount))
        (if (< payout-amount claim-amount)
            (map-set claims claim-key { status: "partially-paid", timestamp: block-height, paid-amount: payout-amount })
            (begin
              (map-delete claims claim-key)
              (map-delete insured-contracts claimant)))
        (print { event: "claim-approved", claimant: claimant, claim-amount: claim-amount, payout-amount: payout-amount })
        (ok payout-amount))
      error (err error))))

;; Function to reject a claim
(define-public (reject-claim (claimant principal) (claim-amount uint))
  (let (
    (claim-key { claimant: claimant, amount: claim-amount })
    (claim-data (unwrap! (map-get? claims claim-key) ERR_CLAIM_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status claim-data) "pending") ERR_CLAIM_ALREADY_PROCESSED)
    (asserts! (< (- block-height (get timestamp claim-data)) CLAIM_EXPIRATION_PERIOD) ERR_CLAIM_NOT_EXPIRED)
    (map-set claims claim-key { status: "rejected", timestamp: (get timestamp claim-data), paid-amount: u0 })
    (print { event: "claim-rejected", claimant: claimant, claim-amount: claim-amount })
    (ok true)))

;; Function to check and expire a single claim
(define-public (check-and-expire-claim (claimant principal) (claim-amount uint))
  (let (
    (claim-key { claimant: claimant, amount: claim-amount })
    (claim-data (unwrap! (map-get? claims claim-key) ERR_CLAIM_NOT_FOUND))
  )
    (if (and (is-eq (get status claim-data) "pending")
             (>= (- block-height (get timestamp claim-data)) CLAIM_EXPIRATION_PERIOD))
        (begin
          (map-set claims claim-key { status: "expired", timestamp: (get timestamp claim-data), paid-amount: u0 })
          (print { event: "claim-expired", claimant: claimant, claim-amount: claim-amount })
          (ok true))
        (ok false))))

;; Function to change the contract owner
(define-public (change-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq new-owner 'SP000000000000000000002Q6VF78)) ERR_INVALID_PRINCIPAL)
    (print { event: "contract-owner-changed", old-owner: (var-get contract-owner), new-owner: new-owner })
    (ok (var-set contract-owner new-owner))))

;; Function to get the current insurance pool balance
(define-read-only (get-pool-balance)
  (ok (var-get insurance-pool)))

;; Function to check if a contract is insured
(define-read-only (is-insured (contract principal))
  (is-some (map-get? insured-contracts contract)))

;; Function to get the insured amount for a contract
(define-read-only (get-insured-amount (contract principal))
  (ok (default-to u0 (map-get? insured-contracts contract))))

;; Function to get the claim status for a contract
(define-read-only (get-claim-status (claimant principal) (claim-amount uint))
  (match (map-get? claims { claimant: claimant, amount: claim-amount })
    claim-data (ok { status: (get status claim-data), timestamp: (get timestamp claim-data), paid-amount: (get paid-amount claim-data) })
    ERR_CLAIM_NOT_FOUND))