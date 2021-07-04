(defpackage #:trivial-password-store
  (:use #:cl)
  (:nicknames #:tps)
  (:export #:make-database
           #:new-entry
           #:decrypt-pass-entry
           #:database-to-file
           #:load-db
           #:get-pass-entry/ies))
