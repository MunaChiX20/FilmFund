;; FilmFund Crowdfunding Platform
;; Decentralized film funding platform

(define-map campaigns uint {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    goal: uint,
    raised: uint,
    deadline: uint,
    active: bool,
    funded: bool
})

(define-map contributions {campaign-id: uint, contributor: principal} uint)
(define-map campaign-contributors uint (list 100 principal))

(define-data-var next-campaign-id uint u1)
(define-data-var platform-fee uint u300) ;; 3% fee

(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u401))
(define-constant err-not-found (err u404))
(define-constant err-campaign-ended (err u410))
(define-constant err-invalid-amount (err u400))
(define-constant err-campaign-active (err u409))
(define-constant err-already-funded (err u411))

;; Helper function to get current block height as time proxy
(define-read-only (get-current-time)
    block-height
)

(define-public (create-campaign (title (string-ascii 100)) (description (string-ascii 500)) (goal uint) (duration uint))
    (let ((campaign-id (var-get next-campaign-id)))
        (asserts! (> (len title) u0) err-invalid-amount)
        (asserts! (> goal u0) err-invalid-amount)
        (asserts! (> duration u0) err-invalid-amount)
        (map-set campaigns campaign-id {
            creator: tx-sender,
            title: title,
            description: description,
            goal: goal,
            raised: u0,
            deadline: (+ (get-current-time) duration),
            active: true,
            funded: false
        })
        (var-set next-campaign-id (+ campaign-id u1))
        (ok campaign-id)
    )
)

(define-public (contribute (campaign-id uint) (amount uint))
    (let (
        (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
        (current-time (get-current-time))
        (existing-contribution (default-to u0 (map-get? contributions {campaign-id: campaign-id, contributor: tx-sender})))
    )
        (asserts! (get active campaign) err-campaign-ended)
        (asserts! (< current-time (get deadline campaign)) err-campaign-ended)
        (asserts! (> amount u0) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set contributions {campaign-id: campaign-id, contributor: tx-sender} (+ existing-contribution amount))
        (map-set campaigns campaign-id (merge campaign {raised: (+ (get raised campaign) amount)}))
        (ok true)
    )
)

(define-public (finalize-campaign (campaign-id uint))
    (let (
        (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
        (current-time (get-current-time))
        (raised (get raised campaign))
        (goal (get goal campaign))
        (creator (get creator campaign))
    )
        (asserts! (is-eq tx-sender creator) err-not-authorized)
        (asserts! (get active campaign) err-campaign-active)
        (asserts! (>= current-time (get deadline campaign)) err-campaign-active)
        (if (>= raised goal)
            (let ((fee (/ (* raised (var-get platform-fee)) u10000)))
                (try! (as-contract (stx-transfer? (- raised fee) tx-sender creator)))
                (try! (as-contract (stx-transfer? fee tx-sender contract-owner)))
                (map-set campaigns campaign-id (merge campaign {active: false, funded: true}))
                (ok true)
            )
            (begin
                (map-set campaigns campaign-id (merge campaign {active: false}))
                (ok false)
            )
        )
    )
)

(define-public (refund (campaign-id uint))
    (let (
        (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
        (contribution (unwrap! (map-get? contributions {campaign-id: campaign-id, contributor: tx-sender}) err-not-found))
    )
        (asserts! (not (get active campaign)) err-campaign-active)
        (asserts! (not (get funded campaign)) err-not-authorized)
        (try! (as-contract (stx-transfer? contribution tx-sender tx-sender)))
        (map-delete contributions {campaign-id: campaign-id, contributor: tx-sender})
        (ok true)
    )
)

;; Additional helper functions for better functionality
(define-public (withdraw-funds (campaign-id uint))
    (let (
        (campaign (unwrap! (map-get? campaigns campaign-id) err-not-found))
        (raised (get raised campaign))
        (goal (get goal campaign))
        (creator (get creator campaign))
    )
        (asserts! (is-eq tx-sender creator) err-not-authorized)
        (asserts! (not (get active campaign)) err-campaign-active)
        (asserts! (get funded campaign) err-not-authorized)
        (asserts! (>= raised goal) err-already-funded)
        (let ((fee (/ (* raised (var-get platform-fee)) u10000)))
            (try! (as-contract (stx-transfer? (- raised fee) tx-sender creator)))
            (try! (as-contract (stx-transfer? fee tx-sender contract-owner)))
            (ok true)
        )
    )
)

(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns campaign-id)
)

(define-read-only (get-contribution (campaign-id uint) (contributor principal))
    (map-get? contributions {campaign-id: campaign-id, contributor: contributor})
)

(define-read-only (get-campaign-stats (campaign-id uint))
    (match (map-get? campaigns campaign-id)
        campaign (ok {
            progress: (if (> (get goal campaign) u0) 
                         (/ (* (get raised campaign) u100) (get goal campaign)) 
                         u0),
            time-left: (if (> (get deadline campaign) (get-current-time)) 
                          (- (get deadline campaign) (get-current-time)) 
                          u0),
            is-successful: (>= (get raised campaign) (get goal campaign))
        })
        err-not-found
    )
)

(define-read-only (get-platform-fee)
    (var-get platform-fee)
)

(define-public (update-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
        (asserts! (<= new-fee u1000) err-invalid-amount) ;; Max 10% fee
        (var-set platform-fee new-fee)
        (ok true)
    )
)