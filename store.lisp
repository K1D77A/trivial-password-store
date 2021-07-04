(in-package #:trivial-password-store)

(defun hash-password (password digest)
  "Takes in a string and a keyword, the keyword is digest supported by ironclad"
  (ironclad:byte-array-to-hex-string 
   (ironclad:digest-sequence 
    digest
    (ironclad:ascii-string-to-byte-array password))))

(defclass database ()
  ((%location
    :accessor location
    :initarg :location)
   (%name
    :accessor name
    :initarg :name)
   (%list-of-groups
    :accessor list-of-groups
    :initarg :list-of-groups
    :initform ()
    :type list)))

(defmethod print-object ((object database) stream)
  (print-unreadable-object (object stream)
    (format stream "Location ~A~%Name ~A~%Groups: ~A~%"
            (location object)
            (name object)
            (list-of-groups object))))

(defclass group ()
  ((%name
    :accessor name
    :initarg :name)
   (%list-of-entries
    :accessor list-of-entries
    :initform ()
    :initarg :list-of-entries)))

(defmethod print-object ((object group) stream)
  (print-unreadable-object (object stream)
    (format stream "Name ~A~%Entries: ~A~%"
            (name object)
            (list-of-entries object))))

(defclass pass-entry ()
  ((%name
    :accessor name
    :initarg :name)))

(defclass encrypted-pass-entry (pass-entry)
  ((%encrypted-pass
    :accessor encrypted-pass
    :initarg :encrypted-pass)))

(defmethod print-object ((object encrypted-pass-entry) stream)
  (print-unreadable-object (object stream)
    (format stream "Name ~A~%Encrypted-pass: ~A~%"
            (name object)
            (encrypted-pass object))))

(defclass decrypted-pass-entry (pass-entry)
  ((%decrypted-pass
    :accessor decrypted-pass
    :initarg :decrypted-pass)))

(defmethod print-object ((object decrypted-pass-entry) stream)
  (print-unreadable-object (object stream)
    (format stream "Name ~A~%Decrypted-pass: ~A~%"
            (name object)
            (decrypted-pass object))))

(defun str-to-octets (str)
  (ironclad:ascii-string-to-byte-array str))

(defun arr-to-str (str)
  (babel:octets-to-string str))

(defun make-database (location name)
  (check-type location (or string pathname))
  (check-type name string)
  (make-instance 'database :name name :location location))

(defvar *database* (make-database "./db.txt" "db"))

(defun make-pass-entry (name to-encrypt pass)
  (check-type name string)
  (check-type pass string)
  (check-type to-encrypt string)
  (let* ((cipher (gen-cipher pass))
         (pass (encrypt-byte-array cipher (str-to-octets to-encrypt))))
    (make-instance 'encrypted-pass-entry :encrypted-pass pass :name name)))

(defmethod decrypt ((pass string) (pass-entry encrypted-pass-entry))
  (decrypt-pass-entry pass pass-entry))

(defmethod decrypt-pass-entry ((pass string) (pass-entry encrypted-pass-entry))
  (let*((cipher (gen-cipher pass))
        (pass (decrypt-byte-array cipher (encrypted-pass pass-entry))))
    (make-instance 'decrypted-pass-entry :name (name pass-entry)
                                         :decrypted-pass (arr-to-str pass))))

(defun make-group (name)
  (check-type name string)
  (make-instance 'group :name name))

(defun add-pass-entry-to-group (group-entry pass-entry)
  (check-type pass-entry encrypted-pass-entry)
  (setf (list-of-entries group-entry) (append (list-of-entries group-entry)
                                              (list pass-entry)))
  group-entry)

(defun add-group-to-database (group database)
  (check-type group group)
  (with-accessors ((entries list-of-groups))
      database
    (if (find (name group) entries :key #'name :test #'string=)
        database 
        (setf entries (append entries (list group))))
    database))

(defun add-pass-entry-to-database (pass-entry group-name database)
  (with-accessors ((groups list-of-groups))
      database
    (let ((exists? (find group-name groups :key #'name :test #'string=)))
      (add-group-to-database
       (if exists?
           (add-pass-entry-to-group exists? pass-entry)
           (add-pass-entry-to-group (make-group group-name)
                                    pass-entry))
       database))))

(defun new-entry (db group entry-name to-encrypt pass)
  (add-pass-entry-to-database (make-pass-entry entry-name to-encrypt pass) group db))

(defmethod display-db (db)
  (print-object db t))

(defun get-group (database group)
  (find group (list-of-groups database) :key #'name :test #'string=))

(defun get-group-names (database)
  (mapcar #'name (list-of-groups database)))

(defun get-name-in-group (database group name)
  (let ((gro (get-group database group)))
    (find name (list-of-entries gro) :key #'name :test #'string=)))

(defun get-pass-entry/ies (database name)
  (let ((groups (get-group-names database)))
    (remove NIL (mapcar (lambda (group)
                          (get-name-in-group database group name))
                        groups))))

(defmethod to-list ((ent encrypted-pass-entry))
  (append (list :entry-name (name ent))
          (list :encrypted-pass (encrypted-pass ent))))

(defmethod to-list ((ent group))
  (append (list :group-name (name ent))
          (mapcar #'to-list (list-of-entries ent))))

(defmethod to-list ((ent database))
  (append (list :location (location ent))
          (list :database-name (name ent))
          (mapcar #'to-list (list-of-groups ent))))

;;;convert from list to encrypted-pass-entry
(defun pass-as-list-p (list)
  (and (string= (first list) :encrypted-pass)
       (string= (third list) :entry-name)))

(deftype pass-list () `(satisfies pass-as-list-p))

(defun pass-from-list (list)
  (check-type list pass-list)
  (make-instance 'encrypted-pass-entry
                 :name (second list)
                 :encrypted-pass (make-array (length (second list))
                                             :element-type '(unsigned-byte 8)
                                             :initial-contents (second list))))
;;;convert from list to group
(defun group-as-list-p (list)
  (and (string= (first list) :GROUP-NAME)
       (listp (third list))))

(deftype group-list () `(satisfies group-as-list-p))

(defun group-from-list (list)
  (check-type list group-list)
  (make-instance 'group :name (second list)
                        :list-of-entries (mapcar #'pass-from-list (nthcdr 2 list))))
;;;convert the database from a list to objects
(defun database-as-list-p (list)
  (and (string= (first list) :LOCATION)
       (string= (third list) :DATABASE-NAME)))

(deftype database-list () `(satisfies database-as-list-p))

(defun database-from-list (list)
  (check-type list database-list)
  (make-instance 'database :location (second list)
                           :name (fourth list)
                           :list-of-groups (mapcar #'group-from-list (nthcdr 4 list))))


(defmethod to-text ((ent database))
  (jonathan:to-json (to-list ent)))

(defun database-to-file (database password)
  (let* ((location (location database))
         (cipher (gen-cipher password))
         (text (encrypt-byte-array cipher (str-to-octets (to-text database)))))
    (format t "saving to location: ~A~%" location)
    (with-open-file (s location :if-exists :supersede
                                :if-does-not-exist :create
                                :element-type '(unsigned-byte 8)
                                :direction :output)
      (write-sequence text s)
      (force-output s))
    (format t "done (maybe)~%")))

(defun len-file (file)
  (with-open-file (s file :element-type '(unsigned-byte 8) :if-does-not-exist nil)
    (file-length s)))

(defun db-file-to-list (file password)
  (let* ((len (len-file file))
         (cipher (gen-cipher password))
         (res (make-array len :element-type '(unsigned-byte 8))))
    (with-open-file (s file :element-type '(unsigned-byte 8))
      (read-sequence res s))
    (jonathan:parse (arr-to-str (decrypt-byte-array cipher res)))))

(defun load-db (file password)
  (check-type file (or pathname string))
  (handler-case (database-from-list (db-file-to-list file password))
    (jonathan.error:<jonathan-incomplete-json-error> ()
      "bad password")))

;;;;all below pertains to encryption
(defvar *prng* (ironclad:make-prng :fortuna))
(ironclad:read-os-random-seed :random *prng*)

(defun rand-data (len)
  "Generates a random byte array after reseeding the prng"  
  (ironclad:random-data len *prng*))

(defun gen-cipher (pass)
  (ironclad:make-cipher :threefish1024
                        :mode :cfb8
                        :initialization-vector (rand-data 128)
                        :key (ironclad:ascii-string-to-byte-array
                              (hash-password pass :sha512))))

(defun seq-total-len (seqs)
  "returns the total length of all the seqs together"
  ;;(declare (optimize (speed 3)(safety 1)))
  (reduce #'+ (mapcar #'length seqs)))

(defun conc-arrs (arrs)
  "concatenate all the arrays within the list arrs and return 1 new array"
  ;;(declare (optimize (speed 3)(safety 1)))
  (apply #'concatenate '(vector (unsigned-byte 8)) arrs))

(defun encrypt-byte-array (cipher byte-array)
  "Takes in a cipher and a byte array and returns a new byte array whose contents has 
been encrypted. The cipher should be in cfb8 mode as this will append a random byte-array
of length (block-length cipher) to the start of the byte-array."
  (let ((byte (conc-arrs (list (rand-data (ironclad:block-length cipher))  byte-array))))
    (ironclad:encrypt-in-place cipher byte)
    byte))

(defun decrypt-byte-array (cipher byte-array)
  "Takes in a cipher and a byte-array and decrypts the byte array. The returned array is not the 
complete decryption but only contains the data that the user wanted encrypted when using 
'encrypt-byte-array', after decryption the array subseq'd (subseq arr (block-length cipher))
to remove the IV block"
  ;; (declare (optimize (speed 3)(safety 1)))
  ;;  (reinitialize-instance cipher)
  (let ((arr byte-array))
    (ironclad:decrypt-in-place cipher arr)
    (subseq arr (ironclad:block-length cipher))))

