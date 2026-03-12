#lang racket/base

(require "../template.rkt")

(provide
 render)

(define (render)
  (template
   #:title "Privacy Policy"
   (haml
    (:main.container.prose
     (:h1 "Privacy Policy")

     (:p "CLEARTYPE SRL built Ruckus as a free app. This page informs visitors "
         "regarding our policies with the collection, use, and disclosure of personal "
         "information.")

     (:h2 "Data Collection")

     (:p "Ruckus does not collect, store, or transmit any personal data. All data "
         "stays on your device. There are no analytics, no tracking, and no "
         "third-party services.")

     (:h2 "Agreement")

     (:p "By using Ruckus, you agree to this privacy policy.")

     (:h2 "Contact")

     (:p "If you have any questions, contact us at "
         (:a ([:href "mailto:bogdan@defn.io"]) "bogdan@defn.io") ".")

     (:p.muted (:em "Last updated: March 11, 2026"))))))
