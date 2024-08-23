;; Smart Contract Insurance

;; Define error constants
(define-constant ERR_INVALID_AMOUNT u100)
(define-constant ERR_INSUFFICIENT_FUNDS u101)
(define-constant ERR_CLAIM_NOT_FOUND u102)
(define-constant ERR_UNAUTHORIZED u103)
(define-constant ERR_ALREADY_INSURED u104)
(define-constant ERR_INVALID_PRINCIPAL u105)

;; Define the contract
(define-data-var insurance-pool uint u0)
(define-data-var contract-owner principal tx-sender)
(define-map insured-contracts principal uint)
(define-map claims principal uint)

;; Function to purchase insurance
(define-public (purchase-insurance (amount uint))
  (let ((caller tx-sender))
    (if (<= amount u0)
        (err ERR_INVALID_AMOUNT)
        (if (is-some (map-get? insured-contracts caller))
            (err ERR_ALREADY_INSURED)
            (begin
              (try! (stx-transfer? amount caller (as-contract tx-sender)))
              (var-set insurance-pool (+ (var-get insurance-pool) amount))
              (map-set insured-contracts caller amount)
              (ok true))))))

;; Function to file a claim
(define-public (file-claim (claim-amount uint))
  (let ((caller tx-sender)
        (insured-amount (default-to u0 (map-get? insured-contracts caller))))
    (if (<= claim-amount u0)
        (err ERR_INVALID_AMOUNT)
        (if (> claim-amount insured-amount)
            (err ERR_INSUFFICIENT_FUNDS)
            (begin
              (map-set claims caller claim-amount)
              (ok true))))))

;; Function to approve and pay out a claim
(define-public (approve-claim (claimant principal))
  (let ((claim-amount (default-to u0 (map-get? claims claimant))))
    (if (is-eq tx-sender (var-get contract-owner))
        (if (<= claim-amount u0)
            (err ERR_CLAIM_NOT_FOUND)
            (if (> claim-amount (var-get insurance-pool))
                (err ERR_INSUFFICIENT_FUNDS)
                (begin
                  (try! (as-contract (stx-transfer? claim-amount tx-sender claimant)))
                  (var-set insurance-pool (- (var-get insurance-pool) claim-amount))
                  (map-delete claims claimant)
                  (map-delete insured-contracts claimant)
                  (ok true))))
        (err ERR_UNAUTHORIZED))))

;; Function to change the contract owner
(define-public (change-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (asserts! (not (is-eq new-owner 'SP000000000000000000002Q6VF78)) (err ERR_INVALID_PRINCIPAL))
    (ok (var-set contract-owner new-owner))))

;; Function to get the current insurance pool balance
(define-read-only (get-pool-balance)
  (ok (var-get insurance-pool)))

;; Function to check if a contract is insured
(define-read-only (is-insured (contract principal))
  (if (is-some (map-get? insured-contracts contract))
      (ok true)
      (ok false)))

;; Function to get the insured amount for a contract
(define-read-only (get-insured-amount (contract principal))
  (ok (default-to u0 (map-get? insured-contracts contract))))

;; Function to get the claim amount for a contract
(define-read-only (get-claim-amount (contract principal))
  (ok (default-to u0 (map-get? claims contract))))