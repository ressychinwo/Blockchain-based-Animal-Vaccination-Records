(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_PARAMS (err u400))
(define-constant ERR_EXPIRED (err u410))

(define-map animals
    { animal-id: uint }
    {
        owner: principal,
        name: (string-ascii 50),
        species: (string-ascii 30),
        breed: (string-ascii 50),
        birth-date: uint,
        microchip-id: (string-ascii 20),
        registered-at: uint,
        is-active: bool,
    }
)

(define-map veterinarians
    { vet-id: principal }
    {
        name: (string-ascii 100),
        license-number: (string-ascii 30),
        clinic-name: (string-ascii 100),
        registered-at: uint,
        is-active: bool,
    }
)

(define-map vaccinations
    { vaccination-id: uint }
    {
        animal-id: uint,
        vet-id: principal,
        vaccine-name: (string-ascii 50),
        manufacturer: (string-ascii 50),
        batch-number: (string-ascii 20),
        vaccination-date: uint,
        expiry-date: uint,
        next-due-date: (optional uint),
        notes: (string-ascii 200),
    }
)

(define-map animal-vaccinations
    {
        animal-id: uint,
        vaccination-id: uint,
    }
    { exists: bool }
)

(define-data-var next-animal-id uint u1)
(define-data-var next-vaccination-id uint u1)

(define-read-only (get-animal (animal-id uint))
    (map-get? animals { animal-id: animal-id })
)

(define-read-only (get-veterinarian (vet-id principal))
    (map-get? veterinarians { vet-id: vet-id })
)

(define-read-only (get-vaccination (vaccination-id uint))
    (map-get? vaccinations { vaccination-id: vaccination-id })
)

(define-read-only (get-current-animal-id)
    (var-get next-animal-id)
)

(define-read-only (get-current-vaccination-id)
    (var-get next-vaccination-id)
)

(define-read-only (is-animal-vaccination-linked
        (animal-id uint)
        (vaccination-id uint)
    )
    (default-to false
        (get exists
            (map-get? animal-vaccinations {
                animal-id: animal-id,
                vaccination-id: vaccination-id,
            })
        ))
)

(define-read-only (is-vaccination-expired (vaccination-id uint))
    (match (map-get? vaccinations { vaccination-id: vaccination-id })
        vaccination-data (let ((current-block stacks-block-height))
            (< (get expiry-date vaccination-data) current-block)
        )
        false
    )
)

(define-read-only (get-animal-owner (animal-id uint))
    (match (map-get? animals { animal-id: animal-id })
        animal-data (some (get owner animal-data))
        none
    )
)

(define-public (register-veterinarian
        (name (string-ascii 100))
        (license-number (string-ascii 30))
        (clinic-name (string-ascii 100))
    )
    (let ((vet-id tx-sender))
        (asserts! (is-none (map-get? veterinarians { vet-id: vet-id }))
            ERR_ALREADY_EXISTS
        )
        (asserts! (> (len name) u0) ERR_INVALID_PARAMS)
        (asserts! (> (len license-number) u0) ERR_INVALID_PARAMS)
        (map-set veterinarians { vet-id: vet-id } {
            name: name,
            license-number: license-number,
            clinic-name: clinic-name,
            registered-at: stacks-block-height,
            is-active: true,
        })
        (ok vet-id)
    )
)

(define-public (deactivate-veterinarian (vet-id principal))
    (let ((vet-data (unwrap! (map-get? veterinarians { vet-id: vet-id }) ERR_NOT_FOUND)))
        (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender vet-id))
            ERR_UNAUTHORIZED
        )
        (map-set veterinarians { vet-id: vet-id }
            (merge vet-data { is-active: false })
        )
        (ok true)
    )
)

(define-public (register-animal
        (name (string-ascii 50))
        (species (string-ascii 30))
        (breed (string-ascii 50))
        (birth-date uint)
        (microchip-id (string-ascii 20))
    )
    (let ((animal-id (var-get next-animal-id)))
        (asserts! (> (len name) u0) ERR_INVALID_PARAMS)
        (asserts! (> (len species) u0) ERR_INVALID_PARAMS)
        (asserts! (<= birth-date stacks-block-height) ERR_INVALID_PARAMS)
        (map-set animals { animal-id: animal-id } {
            owner: tx-sender,
            name: name,
            species: species,
            breed: breed,
            birth-date: birth-date,
            microchip-id: microchip-id,
            registered-at: stacks-block-height,
            is-active: true,
        })
        (var-set next-animal-id (+ animal-id u1))
        (ok animal-id)
    )
)

(define-public (update-animal
        (animal-id uint)
        (name (string-ascii 50))
        (breed (string-ascii 50))
    )
    (let ((animal-data (unwrap! (map-get? animals { animal-id: animal-id }) ERR_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner animal-data)) ERR_UNAUTHORIZED)
        (asserts! (get is-active animal-data) ERR_NOT_FOUND)
        (asserts! (> (len name) u0) ERR_INVALID_PARAMS)
        (map-set animals { animal-id: animal-id }
            (merge animal-data {
                name: name,
                breed: breed,
            })
        )
        (ok true)
    )
)

(define-public (add-vaccination
        (animal-id uint)
        (vaccine-name (string-ascii 50))
        (manufacturer (string-ascii 50))
        (batch-number (string-ascii 20))
        (vaccination-date uint)
        (expiry-date uint)
        (next-due-date (optional uint))
        (notes (string-ascii 200))
    )
    (let (
            (vaccination-id (var-get next-vaccination-id))
            (animal-data (unwrap! (map-get? animals { animal-id: animal-id }) ERR_NOT_FOUND))
            (vet-data (unwrap! (map-get? veterinarians { vet-id: tx-sender })
                ERR_UNAUTHORIZED
            ))
        )
        (asserts! (get is-active animal-data) ERR_NOT_FOUND)
        (asserts! (get is-active vet-data) ERR_UNAUTHORIZED)
        (asserts! (> (len vaccine-name) u0) ERR_INVALID_PARAMS)
        (asserts! (<= vaccination-date stacks-block-height) ERR_INVALID_PARAMS)
        (asserts! (> expiry-date vaccination-date) ERR_INVALID_PARAMS)
        (map-set vaccinations { vaccination-id: vaccination-id } {
            animal-id: animal-id,
            vet-id: tx-sender,
            vaccine-name: vaccine-name,
            manufacturer: manufacturer,
            batch-number: batch-number,
            vaccination-date: vaccination-date,
            expiry-date: expiry-date,
            next-due-date: next-due-date,
            notes: notes,
        })
        (map-set animal-vaccinations {
            animal-id: animal-id,
            vaccination-id: vaccination-id,
        } { exists: true }
        )
        (var-set next-vaccination-id (+ vaccination-id u1))
        (ok vaccination-id)
    )
)

(define-public (update-vaccination-notes
        (vaccination-id uint)
        (notes (string-ascii 200))
    )
    (let ((vaccination-data (unwrap! (map-get? vaccinations { vaccination-id: vaccination-id })
            ERR_NOT_FOUND
        )))
        (asserts! (is-eq tx-sender (get vet-id vaccination-data))
            ERR_UNAUTHORIZED
        )
        (map-set vaccinations { vaccination-id: vaccination-id }
            (merge vaccination-data { notes: notes })
        )
        (ok true)
    )
)

(define-public (transfer-animal-ownership
        (animal-id uint)
        (new-owner principal)
    )
    (let ((animal-data (unwrap! (map-get? animals { animal-id: animal-id }) ERR_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner animal-data)) ERR_UNAUTHORIZED)
        (asserts! (get is-active animal-data) ERR_NOT_FOUND)
        (asserts! (not (is-eq tx-sender new-owner)) ERR_INVALID_PARAMS)
        (map-set animals { animal-id: animal-id }
            (merge animal-data { owner: new-owner })
        )
        (ok true)
    )
)

(define-public (deactivate-animal (animal-id uint))
    (let ((animal-data (unwrap! (map-get? animals { animal-id: animal-id }) ERR_NOT_FOUND)))
        (asserts! (is-eq tx-sender (get owner animal-data)) ERR_UNAUTHORIZED)
        (map-set animals { animal-id: animal-id }
            (merge animal-data { is-active: false })
        )
        (ok true)
    )
)
