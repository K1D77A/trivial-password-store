# trivial-password-store
This is just a trivial password storing facility that stores passwords using threefish1024 with a 128byte IV into a text file which is also encrypted with another pass. This was a challenge from the Web Dev 2.0 Discord server, its not meant to be a serious project
I threw it together to get it done but it seems to work pretty well. 

Just a heads up this doesn't salt the pass, so whenever 'pass' is expected you should probably salt it. 

The main functions are:


* (make-database location name) which creates a new database in LOCATION.

* (new-entry db group entry-name to-encrypt pass) which adds a new encrypted password into the DB within GROUP and named by ENTRY-NAME. PASS is used to encrypt TO-ENCRYPT

* (decrypt-pass-entry pass pass-entry) given an object of type PASS-ENTRY (created by NEW-ENTRY) attempt to decrypt using PASS.
 
* (database-to-file database password) given a DATBASE encrypts the entire thing using PASSWORD and saves it to (location DATABASE)

* (load-db file password) loads FILE and attempts to decrypt it all using PASSWORD and restore it to a database object. 

* (get-pass-entry/ies database name) tries to find the password entry/ies named by NAME within DATABASE and returns them in a list

