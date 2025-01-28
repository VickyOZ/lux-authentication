;; Luxury Watch Authentication and Registry System

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-WATCH-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-FOR-SALE (err u102))
(define-constant ERR-NOT-FOR-SALE (err u103))
(define-constant ERR-INVALID-PRICE (err u104))

;; Data Variables
(define-data-var registry-admin principal tx-sender)
(define-data-var watch-counter uint u0)

;; Data Maps
(define-map WatchRegistry
    { watch-id: uint }
    {
        owner: principal,
        specifications: (string-utf8 256),
        storage-location: (string-utf8 100),
        condition-score: uint,
        for-sale: bool
    }
)

(define-map WatchMarket
    { watch-id: uint }
    {
        price: uint,
        seller: principal
    }
)

;; Administrative Functions
(define-public (set-registry-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get registry-admin)) ERR-NOT-AUTHORIZED)
        (ok (var-set registry-admin new-admin))
    )
)

;; Watch Registration Functions
(define-public (register-watch
    (specifications (string-utf8 256))
    (storage-location (string-utf8 100))
    )
    (let
        (
            (new-watch-id (+ (var-get watch-counter) u1))
        )
        (map-set WatchRegistry
            { watch-id: new-watch-id }
            {
                owner: tx-sender,
                specifications: specifications,
                storage-location: storage-location,
                condition-score: u100,
                for-sale: false
            }
        )
        (var-set watch-counter new-watch-id)
        (ok new-watch-id)
    )
)

(define-public (update-storage-location
    (watch-id uint)
    (new-location (string-utf8 100))
    )
    (let
        (
            (watch (unwrap! (map-get? WatchRegistry { watch-id: watch-id }) ERR-WATCH-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get owner watch)) ERR-NOT-AUTHORIZED)
        (map-set WatchRegistry
            { watch-id: watch-id }
            (merge watch { storage-location: new-location })
        )
        (ok true)
    )
)

;; Market Functions
(define-public (list-watch
    (watch-id uint)
    (price uint)
    )
    (let
        (
            (watch (unwrap! (map-get? WatchRegistry { watch-id: watch-id }) ERR-WATCH-NOT-FOUND))
        )
        (asserts! (is-eq (get owner watch) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (not (get for-sale watch)) ERR-ALREADY-FOR-SALE)
        (asserts! (> price u0) ERR-INVALID-PRICE)

        (map-set WatchMarket
            { watch-id: watch-id }
            {
                price: price,
                seller: tx-sender
            }
        )

        (map-set WatchRegistry
            { watch-id: watch-id }
            (merge watch { for-sale: true })
        )
        (ok true)
    )
)

(define-public (delist-watch (watch-id uint))
    (let
        (
            (watch (unwrap! (map-get? WatchRegistry { watch-id: watch-id }) ERR-WATCH-NOT-FOUND))
            (listing (unwrap! (map-get? WatchMarket { watch-id: watch-id }) ERR-NOT-FOR-SALE))
        )
        (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)

        (map-delete WatchMarket { watch-id: watch-id })
        (map-set WatchRegistry
            { watch-id: watch-id }
            (merge watch { for-sale: false })
        )
        (ok true)
    )
)

(define-public (buy-watch (watch-id uint))
    (let
        (
            (watch (unwrap! (map-get? WatchRegistry { watch-id: watch-id }) ERR-WATCH-NOT-FOUND))
            (listing (unwrap! (map-get? WatchMarket { watch-id: watch-id }) ERR-NOT-FOR-SALE))
        )
        (asserts! (not (is-eq tx-sender (get seller listing))) ERR-NOT-AUTHORIZED)

        (map-delete WatchMarket { watch-id: watch-id })
        (map-set WatchRegistry
            { watch-id: watch-id }
            (merge watch {
                owner: tx-sender,
                for-sale: false
            })
        )
        (ok true)
    )
)

;; Read-Only Functions
(define-read-only (get-watch-details (watch-id uint))
    (map-get? WatchRegistry { watch-id: watch-id })
)

(define-read-only (get-market-listing (watch-id uint))
    (map-get? WatchMarket { watch-id: watch-id })
)

(define-read-only (get-admin)
    (var-get registry-admin)
)