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

;; Define the contract
(define-data-var insurance-pool uint u0)
(define-data-var contract-owner principal tx-sender)
(define-map insured-contracts principal uint)
(define-map claims { claimant: principal, amount: uint } { status: (string-ascii 20) })

;; Function to purchase insurance
(define-public (purchase-insurance (amount uint))
  (let ((caller tx-sender))
    (asserts! (> amount u0) ERR_ZERO_AMOUNT)
    (asserts! (is-none (map-get? insured-contracts caller)) ERR_ALREADY_INSURED)
    (match (stx-transfer? amount caller (as-contract tx-sender))
      success (begin
        (var-set insurance-pool (+ (var-get insurance-pool) amount))
        (map-set insured-contracts caller amount)
        (ok true))
      error (err error))))

;; Function to file a claim
(define-public (file-claim (claim-amount uint))
  (let ((caller tx-sender)
        (insured-amount (default-to u0 (map-get? insured-contracts caller))))
    (asserts! (> claim-amount u0) ERR_ZERO_AMOUNT)
    (asserts! (is-some (map-get? insured-contracts caller)) ERR_NOT_INSURED)
    (asserts! (>= insured-amount claim-amount) ERR_INSUFFICIENT_FUNDS)
    (asserts! (is-none (map-get? claims { claimant: caller, amount: claim-amount })) ERR_CLAIM_ALREADY_PROCESSED)
    (map-set claims { claimant: caller, amount: claim-amount } { status: "pending" })
    (ok true)))

;; Function to approve and pay out a claim
(define-public (approve-claim (claimant principal) (claim-amount uint))
  (let ((claim-data (unwrap! (map-get? claims { claimant: claimant, amount: claim-amount }) ERR_CLAIM_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status claim-data) "pending") ERR_CLAIM_ALREADY_PROCESSED)
    (asserts! (<= claim-amount (var-get insurance-pool)) ERR_INSUFFICIENT_FUNDS)
    (asserts! (> (var-get insurance-pool) u0) ERR_POOL_EMPTY)
    (match (as-contract (stx-transfer? claim-amount tx-sender claimant))
      success (begin
        (var-set insurance-pool (- (var-get insurance-pool) claim-amount))
        (map-delete claims { claimant: claimant, amount: claim-amount })
        (map-delete insured-contracts claimant)
        (ok true))
      error (err error))))

;; Function to reject a claim
(define-public (reject-claim (claimant principal) (claim-amount uint))
  (let ((claim-data (unwrap! (map-get? claims { claimant: claimant, amount: claim-amount }) ERR_CLAIM_NOT_FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status claim-data) "pending") ERR_CLAIM_ALREADY_PROCESSED)
    (map-set claims { claimant: claimant, amount: claim-amount } { status: "rejected" })
    (ok true)))

;; Function to change the contract owner
(define-public (change-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq new-owner 'SP000000000000000000002Q6VF78)) ERR_INVALID_PRINCIPAL)
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
    claim-data (ok (get status claim-data))
    ERR_CLAIM_NOT_FOUND))
