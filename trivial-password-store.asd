(asdf:defsystem #:trivial-password-store
  :description "trivial-password-store"
  :author ""
  :license  "MIT"
  :version "1.0.0"
  :serial t
  :depends-on (#:jonathan
               #:ironclad)
  :components ((:file "package")
               (:file "store")))

