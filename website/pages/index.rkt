#lang racket/base

(require "../template.rkt")

(provide
 render)

(define (render)
  (apply
   template
   #:title "Racket for iOS"
   #:description "A Racket programming environment for your iPhone and iPad. Write, run, and explore Racket code on the go."
   (haml
    (:section.hero
     (:div.hero-glow ([:aria-hidden "true"]))
     (.container
      (.hero-layout.reveal
       (.hero-text
        (:img.hero-icon ([:src "images/app-icon.png"] [:alt "Ruckus app icon"]))
        (:h1 "Ruckus")
        (:p.tagline "Racket for iOS")
        (:p.hero-sub "Write, run, and explore Racket on your iPhone and iPad.")
        (:a.cta-button
         ([:href "https://apps.apple.com/app/ruckus-racket-for-ios/id6746136677"])
         (:img.appstore-badge
          ([:src "https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83"]
           [:alt "Download on the App Store"]))))
       (.hero-screenshots
        (.screenshot-stack
         (:img.ss.ss-back-1 ([:src "images/screenshot-output.png"] [:alt "Script output view"]))
         (:img.ss.ss-back-2 ([:src "images/screenshot-settings.png"] [:alt "App settings"]))
         (:img.ss.ss-front ([:src "images/screenshot-editor.png"] [:alt "Code editor with Racket syntax highlighting"])))))))

    (:section.features
     (.container
      (:h2.section-heading.reveal
       (:span.paren-accent "(") "features" (:span.paren-accent ")"))
      (.features-grid
       ,@(for/list ([(f idx) (in-indexed (in-list features))])
           (feature-card (add1 idx) f)))))

    (:script #<<SCRIPT
const obs = new IntersectionObserver((entries) => {
  entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); obs.unobserve(e.target); } });
}, { threshold: 0.15 });
document.querySelectorAll('.reveal').forEach(el => obs.observe(el));
SCRIPT
             ))))

(define (feature-card num feature)
  (haml
   (.feature-card.reveal
    (:span.feature-num (format "~a" (~a num #:width 2 #:align 'right #:pad-string "0")))
    (:h3 (car feature))
    (:p (cadr feature)))))

(define (~a v #:width w #:align _align #:pad-string pad)
  (define s (format "~a" v))
  (define missing (max 0 (- w (string-length s))))
  (string-append (make-string missing (string-ref pad 0)) s))

(define features
  '(("Run Scripts"
     "Execute Racket programs and see output as it\u2019s produced. Everything runs locally on your device.")
    ("Rainbow Parentheses"
     "Color-coded nesting depth and bracket matching.")
    ("Smart Indentation"
     "Understands Racket forms like define, let, and cond. Includes a keyboard row for brackets and common keywords.")
    ("Color Themes"
     "Catppuccin Mocha, Dracula, Gruvbox, Nord, One Dark, Solarized, and more.")
    ("Find & Replace"
     "Search and replace across your code.")
    ("Shortcuts & Widgets"
     "Run scripts from your home screen or automate them with Shortcuts. Opens .rkt files from Files.")))
