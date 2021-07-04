# trivial-password-store
This is just a trivial password storing facility that stores passwords using threefish1024 with a 128byte IV into a text file which is also encrypted with another pass. This was a challenge from the Web Dev 2.0 Discord server, its not meant to be a serious project
I threw it together to get it done but it seems to work pretty well. 

Just a heads up this doesn't salt the pass, so whenever 'pass' is expected you should probably salt it, however they are hashed with SHA512. 

The main functions are:


`(make-database location name)` which creates a new database in LOCATION.

`(new-entry db group entry-name to-encrypt pass)` which adds a new encrypted password into the DB within GROUP and named by ENTRY-NAME. PASS is used to encrypt TO-ENCRYPT

`(decrypt pass pass-entry)` given an object of type PASS-ENTRY (created by NEW-ENTRY) attempt to decrypt using PASS.
 
`(database-to-file database password)` given a DATABASE encrypts the entire thing using PASSWORD and saves it to (location DATABASE)

`(load-database file password)` loads FILE and attempts to decrypt it all using PASSWORD and restore it to a database object. 

`(get-entry <database | group> name)` tries to find the password entry/ies named by NAME within DATABASE or GROUP and returns them in a list

## Example

### Creation of DB

```lisp
TPS> (make-instance 'database :name "mydb" :location "./mydb.txt")
#<Location ./mydb.txt
Name mydb
Groups: 
>
```

### Creation of entries

```lisp
TPS> (new-entry #v0 "websites" "facebook" "myfacebookpassword" "myentrypassword")
#<Location ./mydb.txt
Name mydb
Groups: websites (1 entries)
>
TPS> (new-entry #v0 "websites" "youtube" "myyoutubepassword" "myentrypassword")
#<Location ./mydb.txt
Name mydb
Groups: websites (2 entries)
>
TPS> (new-entry #v0 "crypto" "crypto.com" "mycrypto.compassword" "specialentrypassword")
#<Location ./mydb.txt
Name mydb
Groups: websites (2 entries), crypto (1 entries)
>
```

### Saving DB

```lisp
TPS> (database-to-file #v0 "mydatabasepassword")
saving to location: ./mydb.txt
done (maybe)
NIL
```

### Loading the DB

bad file

```lisp
TPS> (load-database "./myd.txt" "mydatabasepasswor")
; Debugger entered on #<MISSING-DB {100510AED3}>

```

bad pass

```lisp
TPS> (load-database "./mydb.txt" "mydatabasepasswor")
; Debugger entered on #<BAD-DB-PASSWORD {100709A673}>

```

valid

```lisp
TPS> (load-database "./mydb.txt" "mydatabasepassword")
#<Location ./mydb.txt
Name mydb
Groups: websites (2 entries), crypto (1 entries)
>
```

### Getting entries
You can use the method `get-entry` on both a group or a database in order to 
find an entry by a certain name. This always returns a list.

```lisp
TPS> (get-entry #v2 "facebook")
(#<Name facebook
Encrypted-pass: #(69 184 155 51 8 212 100 117 172 180 198 236 185 100 144 65 18
                  73 148 32 96 133 238 22 142 200 84 36 241 245 95 45 208 97 40
                  34 241 36 44 84 14 45 137 228 226 175 7 188 5 217 160 75 160
                  14 9 51 189 30 114 165 202 215 156 148 223 45 254 199 116 169
                  97 174 11 126 169 16 241 165 140 190 106 25 232 38 38 206 32
                  25 72 36 183 155 115 120 9 143 244 159 128 72 57 173 45 101
                  207 185 178 163 122 120 135 91 64 28 255 93 133 104 42 142
                  249 236 83 58 55 216 212 163 166 37 28 112 115 30 204 246 13
                  189 106 78 151 187 187 17 183 237)
>)
```

### Decrypting entries

Individual entries have their own passwords.

```lisp
TPS> (decrypt "myentrypassword" (first *))
#<Name facebook
Decrypted-pass: myfacebookpassword
>
```


