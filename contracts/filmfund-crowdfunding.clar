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
            deadline: (+ (unwrap-panic (get-stacks-block-info? time (- stx-liquid-supply u1))) (* duration u86400)),
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
        (current-time (unwrap-panic (get-stacks-block-info? time (- stx-liquid-supply u1))))
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
        (current-time (unwrap-panic (get-stacks-block-info? time (- stx-liquid-supply u1))))
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

(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns campaign-id)
)

(define-read-only (get-contribution (campaign-id uint) (contributor principal))
    (map-get? contributions {campaign-id: campaign-id, contributor: contributor})
)