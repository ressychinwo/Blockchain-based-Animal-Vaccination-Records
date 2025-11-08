(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_PARAMS (err u400))
(define-constant ERR_EXPIRED (err u410))
(define-constant ERR_MICROCHIP_REGISTERED (err u1001))
(define-constant ERR_MICROCHIP_NOT_FOUND (err u1004))

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

(define-map microchip-index
    { chip: (string-ascii 20) }
    { animal-id: uint }
)

(define-map vaccination-reminders
    { reminder-id: uint }
    {
        animal-id: uint,
        vaccine-name: (string-ascii 50),
        due-date: uint,
        is-completed: bool,
        created-at: uint,
    }
)

(define-map animal-reminder-index
    {
        animal-id: uint,
        reminder-id: uint,
    }
    { exists: bool }
)

(define-data-var next-animal-id uint u1)
(define-data-var next-vaccination-id uint u1)
(define-data-var next-reminder-id uint u1)

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

(define-read-only (get-animal-id-by-chip (chip (string-ascii 20)))
    (match (map-get? microchip-index { chip: chip })
        entry (some (get animal-id entry))
        none
    )
)

(define-read-only (microchip-is-available (chip (string-ascii 20)))
    (is-none (map-get? microchip-index { chip: chip }))
)

(define-read-only (get-reminder (reminder-id uint))
    (map-get? vaccination-reminders { reminder-id: reminder-id })
)

(define-read-only (is-reminder-overdue (reminder-id uint))
    (match (map-get? vaccination-reminders { reminder-id: reminder-id })
        reminder-data (and
            (< (get due-date reminder-data) stacks-block-height)
            (not (get is-completed reminder-data))
        )
        false
    )
)

(define-read-only (get-animal-reminder-status
        (animal-id uint)
        (reminder-id uint)
    )
    (default-to false
        (get exists
            (map-get? animal-reminder-index {
                animal-id: animal-id,
                reminder-id: reminder-id,
            })
        ))
)

(define-public (register-microchip
        (chip (string-ascii 20))
        (animal-id uint)
    )
    (if (is-some (map-get? microchip-index { chip: chip }))
        ERR_MICROCHIP_REGISTERED
        (begin
            (map-set microchip-index { chip: chip } { animal-id: animal-id })
            (ok animal-id)
        )
    )
)

(define-public (unregister-microchip (chip (string-ascii 20)))
    (match (map-get? microchip-index { chip: chip })
        entry (begin
            (map-delete microchip-index { chip: chip })
            (ok (get animal-id entry))
        )
        ERR_MICROCHIP_NOT_FOUND
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
        (asserts! (> (len microchip-id) u0) ERR_INVALID_PARAMS)
        (asserts! (microchip-is-available microchip-id) ERR_MICROCHIP_REGISTERED)
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
        (try! (register-microchip microchip-id animal-id))
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

(define-public (create-vaccination-reminder
        (animal-id uint)
        (vaccine-name (string-ascii 50))
        (due-date uint)
    )
    (let (
            (animal-data (unwrap! (map-get? animals { animal-id: animal-id }) ERR_NOT_FOUND))
            (reminder-id (var-get next-reminder-id))
        )
        (asserts!
            (or
                (is-eq tx-sender (get owner animal-data))
                (is-some (map-get? veterinarians { vet-id: tx-sender }))
            )
            ERR_UNAUTHORIZED
        )
        (asserts! (get is-active animal-data) ERR_NOT_FOUND)
        (asserts! (> (len vaccine-name) u0) ERR_INVALID_PARAMS)
        (asserts! (> due-date stacks-block-height) ERR_INVALID_PARAMS)
        (map-set vaccination-reminders { reminder-id: reminder-id } {
            animal-id: animal-id,
            vaccine-name: vaccine-name,
            due-date: due-date,
            is-completed: false,
            created-at: stacks-block-height,
        })
        (map-set animal-reminder-index {
            animal-id: animal-id,
            reminder-id: reminder-id,
        } { exists: true }
        )
        (var-set next-reminder-id (+ reminder-id u1))
        (ok reminder-id)
    )
)

(define-public (complete-vaccination-reminder (reminder-id uint))
    (let ((reminder-data (unwrap! (map-get? vaccination-reminders { reminder-id: reminder-id })
            ERR_NOT_FOUND
        )))
        (let ((animal-data (unwrap!
                (map-get? animals { animal-id: (get animal-id reminder-data) })
                ERR_NOT_FOUND
            )))
            (asserts!
                (or
                    (is-eq tx-sender (get owner animal-data))
                    (is-some (map-get? veterinarians { vet-id: tx-sender }))
                )
                ERR_UNAUTHORIZED
            )
            (asserts! (not (get is-completed reminder-data)) ERR_INVALID_PARAMS)
            (map-set vaccination-reminders { reminder-id: reminder-id }
                (merge reminder-data { is-completed: true })
            )
            (ok true)
        )
    )
)

(define-public (cancel-vaccination-reminder (reminder-id uint))
    (let ((reminder-data (unwrap! (map-get? vaccination-reminders { reminder-id: reminder-id })
            ERR_NOT_FOUND
        )))
        (let ((animal-data (unwrap!
                (map-get? animals { animal-id: (get animal-id reminder-data) })
                ERR_NOT_FOUND
            )))
            (asserts! (is-eq tx-sender (get owner animal-data)) ERR_UNAUTHORIZED)
            (map-delete vaccination-reminders { reminder-id: reminder-id })
            (map-delete animal-reminder-index {
                animal-id: (get animal-id reminder-data),
                reminder-id: reminder-id,
            })
            (ok true)
        )
    )
)
