
;; go-smart
;; Smart Contract Insurance

;; Define the contract
(define-data-var insurance-pool uint u0)
(define-map insured-contracts principal uint)
(define-map claims principal uint)

;; Function to purchase insurance
(define-public (purchase-insurance (amount uint))
  (let ((caller tx-sender))
    (if (> amount u0)
        (begin
          (try! (stx-transfer? amount caller (as-contract tx-sender)))
          (var-set insurance-pool (+ (var-get insurance-pool) amount))
          (map-set insured-contracts caller amount)
          (ok true))
        (err u0))))

;; Function to file a claim
(define-public (file-claim (claim-amount uint))
  (let ((caller tx-sender)
        (insured-amount (default-to u0 (map-get? insured-contracts caller))))
    (if (and (> claim-amount u0) (<= claim-amount insured-amount))
        (begin
          (map-set claims caller claim-amount)
          (ok true))
        (err u1))))

;; Function to approve and pay out a claim
(define-public (approve-claim (claimant principal))
  (let ((claim-amount (default-to u0 (map-get? claims claimant))))
    (if (and (> claim-amount u0) (<= claim-amount (var-get insurance-pool)))
        (begin
          (try! (as-contract (stx-transfer? claim-amount tx-sender claimant)))
          (var-set insurance-pool (- (var-get insurance-pool) claim-amount))
          (map-delete claims claimant)
          (map-delete insured-contracts claimant)
          (ok true))
        (err u2))))

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
  