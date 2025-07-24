;; Life Stage Adaptation Contract
;; Helps navigate major life transitions like parenthood or retirement

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-ADAPTATION-NOT-FOUND (err u301))
(define-constant ERR-INVALID-STAGE (err u302))
(define-constant ERR-INVALID-INPUT (err u303))
(define-constant ERR-GOAL-NOT-FOUND (err u304))

;; Data Variables
(define-data-var next-adaptation-id uint u1)
(define-data-var contract-active bool true)

;; Data Maps
(define-map life-stage-adaptations
  { adaptation-id: uint }
  {
    owner: principal,
    life-stage: (string-ascii 30), ;; "parenthood", "retirement", "career-peak", "empty-nest", etc.
    age-range: (string-ascii 20),
    adaptation-phase: (string-ascii 30),
    readiness-score: uint, ;; 1-100 scale
    support-network-size: uint,
    resource-access-level: uint, ;; 1-10 scale
    stress-level: uint, ;; 1-10 scale
    confidence-level: uint, ;; 1-10 scale
    start-date: uint,
    target-adaptation-date: (optional uint),
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map adaptation-goals
  { adaptation-id: uint, goal-id: uint }
  {
    category: (string-ascii 30), ;; "emotional", "practical", "social", "financial", "health"
    title: (string-ascii 100),
    description: (string-ascii 300),
    priority-level: uint, ;; 1-5 scale
    target-date: uint,
    progress-percentage: uint,
    completed: bool,
    completed-at: (optional uint),
    milestones: (list 5 (string-ascii 50))
  }
)

(define-map adaptation-resources
  { adaptation-id: uint, resource-id: uint }
  {
    resource-type: (string-ascii 30), ;; "educational", "support-group", "professional", "tool"
    title: (string-ascii 100),
    description: (string-ascii 300),
    accessibility: (string-ascii 20), ;; "free", "paid", "insurance-covered"
    effectiveness-rating: uint, ;; 1-10 scale
    usage-frequency: (string-ascii 20),
    last-accessed: (optional uint)
  }
)

(define-map adaptation-milestones
  { adaptation-id: uint, milestone-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 300),
    category: (string-ascii 30),
    target-date: uint,
    achieved: bool,
    achieved-date: (optional uint),
    significance-level: uint, ;; 1-10 scale
    celebration-planned: bool
  }
)

(define-map adaptation-assessments
  { adaptation-id: uint, assessment-date: uint }
  {
    overall-adaptation-score: uint, ;; 1-100 scale
    emotional-wellbeing: uint, ;; 1-10 scale
    practical-preparedness: uint, ;; 1-10 scale
    social-integration: uint, ;; 1-10 scale
    financial-stability: uint, ;; 1-10 scale
    health-status: uint, ;; 1-10 scale
    areas-for-improvement: (list 5 (string-ascii 50)),
    strengths-identified: (list 5 (string-ascii 50))
  }
)

;; Private Functions
(define-private (is-adaptation-owner (adaptation-id uint) (user principal))
  (match (map-get? life-stage-adaptations { adaptation-id: adaptation-id })
    adaptation (is-eq (get owner adaptation) user)
    false
  )
)

(define-private (validate-score (score uint) (max-value uint))
  (and (>= score u1) (<= score max-value))
)

(define-private (calculate-readiness-score (emotional uint) (practical uint) (social uint) (financial uint) (health uint))
  (/ (+ emotional practical social financial health) u5)
)

(define-private (get-adaptation-phases (life-stage (string-ascii 30)))
  (if (is-eq life-stage "parenthood")
    (list "preparation" "adjustment" "establishment" "mastery")
    (if (is-eq life-stage "retirement")
      (list "pre-retirement" "transition" "honeymoon" "establishment" "stability")
      (list "awareness" "preparation" "transition" "adaptation" "integration")
    )
  )
)

;; Public Functions

;; Register a new life stage adaptation
(define-public (register-life-stage
  (life-stage (string-ascii 30))
  (age-range (string-ascii 20))
  (initial-readiness-score uint)
  (support-network-size uint)
  (target-adaptation-months uint))
  (let (
    (adaptation-id (var-get next-adaptation-id))
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    (target-date (+ current-time (* target-adaptation-months u2592000))) ;; 30 days * months
    (phases (get-adaptation-phases life-stage))
    (initial-phase (unwrap-panic (element-at phases u0)))
  )
    (asserts! (var-get contract-active) ERR-NOT-AUTHORIZED)
    (asserts! (validate-score initial-readiness-score u100) ERR-INVALID-INPUT)
    (asserts! (> (len life-stage) u0) ERR-INVALID-INPUT)
    (asserts! (> target-adaptation-months u0) ERR-INVALID-INPUT)

    ;; Create adaptation record
    (map-set life-stage-adaptations
      { adaptation-id: adaptation-id }
      {
        owner: tx-sender,
        life-stage: life-stage,
        age-range: age-range,
        adaptation-phase: initial-phase,
        readiness-score: initial-readiness-score,
        support-network-size: support-network-size,
        resource-access-level: u5, ;; Default medium access
        stress-level: u5, ;; Default medium stress
        confidence-level: u5, ;; Default medium confidence
        start-date: current-time,
        target-adaptation-date: (some target-date),
        status: "active",
        created-at: current-time
      }
    )

    (var-set next-adaptation-id (+ adaptation-id u1))
    (ok adaptation-id)
  )
)

;; Set adaptation goals
(define-public (set-adaptation-goals
  (adaptation-id uint)
  (goal-id uint)
  (category (string-ascii 30))
  (title (string-ascii 100))
  (description (string-ascii 300))
  (priority-level uint)
  (target-months uint))
  (let (
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    (target-date (+ current-time (* target-months u2592000)))
  )
    (asserts! (is-adaptation-owner adaptation-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-score priority-level u5) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)

    (map-set adaptation-goals
      { adaptation-id: adaptation-id, goal-id: goal-id }
      {
        category: category,
        title: title,
        description: description,
        priority-level: priority-level,
        target-date: target-date,
        progress-percentage: u0,
        completed: false,
        completed-at: none,
        milestones: (list)
      }
    )
    (ok true)
  )
)

;; Update goal progress
(define-public (update-goal-progress (adaptation-id uint) (goal-id uint) (progress-percentage uint))
  (let (
    (goal (unwrap! (map-get? adaptation-goals { adaptation-id: adaptation-id, goal-id: goal-id }) ERR-GOAL-NOT-FOUND))
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
  )
    (asserts! (is-adaptation-owner adaptation-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-score progress-percentage u100) ERR-INVALID-INPUT)

    (map-set adaptation-goals
      { adaptation-id: adaptation-id, goal-id: goal-id }
      (merge goal {
        progress-percentage: progress-percentage,
        completed: (>= progress-percentage u100),
        completed-at: (if (>= progress-percentage u100) (some current-time) none)
      })
    )
    (ok true)
  )
)

;; Track milestone achievement
(define-public (track-milestone
  (adaptation-id uint)
  (milestone-id uint)
  (title (string-ascii 100))
  (description (string-ascii 300))
  (category (string-ascii 30))
  (significance-level uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-adaptation-owner adaptation-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-score significance-level u10) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)

    (map-set adaptation-milestones
      { adaptation-id: adaptation-id, milestone-id: milestone-id }
      {
        title: title,
        description: description,
        category: category,
        target-date: current-time,
        achieved: true,
        achieved-date: (some current-time),
        significance-level: significance-level,
        celebration-planned: false
      }
    )
    (ok true)
  )
)

;; Add adaptation resource
(define-public (add-resource
  (adaptation-id uint)
  (resource-id uint)
  (resource-type (string-ascii 30))
  (title (string-ascii 100))
  (description (string-ascii 300))
  (accessibility (string-ascii 20))
  (effectiveness-rating uint))
  (begin
    (asserts! (is-adaptation-owner adaptation-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-score effectiveness-rating u10) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)

    (map-set adaptation-resources
      { adaptation-id: adaptation-id, resource-id: resource-id }
      {
        resource-type: resource-type,
        title: title,
        description: description,
        accessibility: accessibility,
        effectiveness-rating: effectiveness-rating,
        usage-frequency: "never",
        last-accessed: none
      }
    )
    (ok true)
  )
)

;; Conduct adaptation assessment
(define-public (conduct-assessment
  (adaptation-id uint)
  (emotional-wellbeing uint)
  (practical-preparedness uint)
  (social-integration uint)
  (financial-stability uint)
  (health-status uint))
  (let (
    (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    (overall-score (calculate-readiness-score emotional-wellbeing practical-preparedness social-integration financial-stability health-status))
  )
    (asserts! (is-adaptation-owner adaptation-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-score emotional-wellbeing u10) ERR-INVALID-INPUT)
    (asserts! (validate-score practical-preparedness u10) ERR-INVALID-INPUT)
    (asserts! (validate-score social-integration u10) ERR-INVALID-INPUT)
    (asserts! (validate-score financial-stability u10) ERR-INVALID-INPUT)
    (asserts! (validate-score health-status u10) ERR-INVALID-INPUT)

    (map-set adaptation-assessments
      { adaptation-id: adaptation-id, assessment-date: current-time }
      {
        overall-adaptation-score: overall-score,
        emotional-wellbeing: emotional-wellbeing,
        practical-preparedness: practical-preparedness,
        social-integration: social-integration,
        financial-stability: financial-stability,
        health-status: health-status,
        areas-for-improvement: (list),
        strengths-identified: (list)
      }
    )

    ;; Update adaptation record with new scores
    (match (map-get? life-stage-adaptations { adaptation-id: adaptation-id })
      adaptation (map-set life-stage-adaptations
        { adaptation-id: adaptation-id }
        (merge adaptation {
          readiness-score: overall-score,
          confidence-level: (/ (+ emotional-wellbeing practical-preparedness) u2)
        })
      )
      false
    )

    (ok overall-score)
  )
)

;; Update adaptation phase
(define-public (advance-adaptation-phase (adaptation-id uint) (new-phase (string-ascii 30)))
  (let ((adaptation (unwrap! (map-get? life-stage-adaptations { adaptation-id: adaptation-id }) ERR-ADAPTATION-NOT-FOUND)))
    (asserts! (is-adaptation-owner adaptation-id tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-phase) u0) ERR-INVALID-INPUT)

    (map-set life-stage-adaptations
      { adaptation-id: adaptation-id }
      (merge adaptation { adaptation-phase: new-phase })
    )
    (ok true)
  )
)

;; Read-only functions

;; Get adaptation details
(define-read-only (get-adaptation (adaptation-id uint))
  (map-get? life-stage-adaptations { adaptation-id: adaptation-id })
)

;; Get adaptation goal
(define-read-only (get-goal (adaptation-id uint) (goal-id uint))
  (map-get? adaptation-goals { adaptation-id: adaptation-id, goal-id: goal-id })
)

;; Get adaptation resource
(define-read-only (get-resource (adaptation-id uint) (resource-id uint))
  (map-get? adaptation-resources { adaptation-id: adaptation-id, resource-id: resource-id })
)

;; Get milestone
(define-read-only (get-milestone (adaptation-id uint) (milestone-id uint))
  (map-get? adaptation-milestones { adaptation-id: adaptation-id, milestone-id: milestone-id })
)

;; Get assessment
(define-read-only (get-assessment (adaptation-id uint) (assessment-date uint))
  (map-get? adaptation-assessments { adaptation-id: adaptation-id, assessment-date: assessment-date })
)

;; Calculate adaptation score
(define-read-only (get-adaptation-score (adaptation-id uint))
  (match (map-get? life-stage-adaptations { adaptation-id: adaptation-id })
    adaptation (some (get readiness-score adaptation))
    none
  )
)

;; Get next adaptation ID
(define-read-only (get-next-adaptation-id)
  (var-get next-adaptation-id)
)

;; Admin functions

;; Toggle contract active status
(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)
