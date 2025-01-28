;; Luxury Watch Authentication and Registry System

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-WATCH-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-FOR-SALE (err u102))
(define-constant ERR-NOT-FOR-SALE (err u103))
(define-constant ERR-INVALID-PRICE (err u104))
(define-constant ERR-INVALID-WATCH-ID (err u105))
(define-constant ERR-INVALID-INPUT (err u106))
(define-constant ERR-INVALID-SCORE (err u107))

;; Data Variables
(define-data-var registry-admin principal tx-sender)
(define-data-var watch-counter uint u0)

;; Map for Authorized Certifiers
(define-map AuthorizedCertifiers
    principal 
    bool
)

;; Helper Functions
(define-private (is-valid-watch-id (id uint))
    (and 
        (> id u0)
        (<= id (var-get watch-counter))
    )
)

(define-private (is-valid-string (str (string-utf8 256)))
    (and 
        (> (len str) u0)
        (< (len str) u256)
    )
)

(define-private (is-valid-location (loc (string-utf8 100)))
    (and 
        (> (len loc) u0)
        (< (len loc) u100)
    )
)

(define-private (is-valid-condition-score (score uint))
    (and 
        (>= score u0)
        (<= score u100)
    )
)

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
        (asserts! (not (is-eq new-admin tx-sender)) ERR-INVALID-INPUT)
        (ok (var-set registry-admin new-admin))
    )
)

(define-public (set-certifier-status (certifier principal) (status bool))
    (begin
        (asserts! (is-eq tx-sender (var-get registry-admin)) ERR-NOT-AUTHORIZED)
        (ok (map-set AuthorizedCertifiers certifier status))
    )
)

;; Watch Registration Functions
(define-public (register-watch
    (specifications (string-utf8 256))
    (storage-location (string-utf8 100))
    )
    (begin
        (asserts! (is-valid-string specifications) ERR-INVALID-INPUT)
        (asserts! (is-valid-location storage-location) ERR-INVALID-INPUT)
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
)

(define-public (update-storage-location
    (watch-id uint)
    (new-location (string-utf8 100))
    )
    (begin
        (asserts! (is-valid-watch-id watch-id) ERR-INVALID-WATCH-ID)
        (asserts! (is-valid-location new-location) ERR-INVALID-INPUT)
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
)

(define-public (update-condition-score
    (watch-id uint)
    (new-score uint)
    )
    (begin
        (asserts! (is-valid-watch-id watch-id) ERR-INVALID-WATCH-ID)
        (asserts! (is-valid-condition-score new-score) ERR-INVALID-SCORE)
        (asserts! (default-to false (map-get? AuthorizedCertifiers tx-sender)) ERR-NOT-AUTHORIZED)
        
        (let
            (
                (watch (unwrap! (map-get? WatchRegistry { watch-id: watch-id }) ERR-WATCH-NOT-FOUND))
            )
            (map-set WatchRegistry
                { watch-id: watch-id }
                (merge watch { condition-score: new-score })
            )
            (ok true)
        )
    )
)

(define-public (transfer-watch
    (watch-id uint)
    (recipient principal)
    )
    (begin
        (asserts! (is-valid-watch-id watch-id) ERR-INVALID-WATCH-ID)
        (asserts! (not (is-eq recipient tx-sender)) ERR-INVALID-INPUT)
        
        (let
            (
                (watch (unwrap! (map-get? WatchRegistry { watch-id: watch-id }) ERR-WATCH-NOT-FOUND))
            )
            ;; Check ownership and not for sale
            (asserts! (is-eq (get owner watch) tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (not (get for-sale watch)) ERR-ALREADY-FOR-SALE)
            
            (map-set WatchRegistry
                { watch-id: watch-id }
                (merge watch { owner: recipient })
            )
            (ok true)
        )
    )
)

;; Market Functions
(define-public (list-watch
    (watch-id uint)
    (price uint)
    )
    (begin
        (asserts! (is-valid-watch-id watch-id) ERR-INVALID-WATCH-ID)
        (asserts! (> price u0) ERR-INVALID-PRICE)
        (let
            (
                (watch (unwrap! (map-get? WatchRegistry { watch-id: watch-id }) ERR-WATCH-NOT-FOUND))
            )
            (asserts! (is-eq (get owner watch) tx-sender) ERR-NOT-AUTHORIZED)
            (asserts! (not (get for-sale watch)) ERR-ALREADY-FOR-SALE)

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
)

(define-public (delist-watch (watch-id uint))
    (begin
        (asserts! (is-valid-watch-id watch-id) ERR-INVALID-WATCH-ID)
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
)

(define-public (buy-watch (watch-id uint))
    (begin
        (asserts! (is-valid-watch-id watch-id) ERR-INVALID-WATCH-ID)
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
)

;; Read-Only Functions
(define-read-only (get-watch-details (watch-id uint))
    (if (is-valid-watch-id watch-id)
        (map-get? WatchRegistry { watch-id: watch-id })
        none
    )
)

(define-read-only (get-market-listing (watch-id uint))
    (if (is-valid-watch-id watch-id)
        (map-get? WatchMarket { watch-id: watch-id })
        none
    )
)

(define-read-only (get-admin)
    (var-get registry-admin)
)

(define-read-only (is-certifier (address principal))
    (default-to false (map-get? AuthorizedCertifiers address))
)