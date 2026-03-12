#lang racket/base

(require koyo/haml
         racket/date)

(provide
 (all-from-out koyo/haml)
 template)

(define (template #:title title
                  #:description [description #f]
                  . content)
  (let ([title (format "Ruckus: ~a" title)])
    (haml
     (:html
      ([:lang "en"])
      (:head
       (:meta ([:charset "utf-8"]))
       (:meta ([:name "viewport"] [:content "width=device-width, initial-scale=1.0"]))
       (:link ([:rel "icon"] [:type "image/png"] [:href "images/app-icon.png"]))
       (:title title)
       ,@(if description (list `(meta ([name "description"] [content ,description]))) null)
       (:link ([:rel "preconnect"] [:href "https://fonts.googleapis.com"]))
       (:link ([:rel "preconnect"] [:href "https://fonts.gstatic.com"] [:crossorigin ""]))
       (:link ([:href "https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400..900&family=DM+Sans:opsz,wght@9..40,300..700&family=JetBrains+Mono:wght@400&display=swap"]
               [:rel "stylesheet"]))
       (:link ([:rel "stylesheet"] [:href "style.css"])))
      (:body
       (header-nav)
       ,@content
       (:footer.footer
        (.container.footer-inner
         (:p &copy (format "~a CLEARTYPE SRL" (date-year (current-date))))
         (:nav.footer-nav
          (:a ([:href "privacy.html"]) "Privacy")
          (:a ([:href "https://github.com/Bogdanp/Ruckus"]) "GitHub")
          (:a ([:href "https://defn.io"]) "defn.io")))))))))

(define (header-nav)
  (haml
   (:header.header
    (.container.header-inner
     (:a.header-brand
      ([:href "index.html"])
      (:img.header-icon ([:src "images/app-icon.png"] [:alt ""] [:width "28"] [:height "28"]))
      (:span "Ruckus"))
     (:nav.header-nav
      (:a ([:href "https://github.com/Bogdanp/Ruckus"]) "GitHub")
      (:a ([:href "privacy.html"]) "Privacy"))))))
