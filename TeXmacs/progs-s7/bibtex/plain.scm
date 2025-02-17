
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : plain.scm
;; DESCRIPTION : plain style for BibTeX files
;; COPYRIGHT   : (C) 2010, 2015  David MICHEL, Joris van der Hoeven
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; To translate (except in french):
;; "edition"
;; "editor"
;; "editors"
;; "master's thesis"
;; "in"
;; "number" ???
;; "of"
;; "pages"
;; "phd thesis"
;; "technical report"
;; "volume"

(texmacs-module (bibtex plain)
  (:use (bibtex bib-utils)))

(bib-define-style "plain" "plain")

(tm-define (bib-preprocessing t) (:mode bib-plain?) `())

(define (bib-non-breaking x)
  (cond ((tm-func? x 'concat)
         (with l (map bib-non-breaking (tm-children x))
           (apply tmconcat l)))
        ((string? x)
         (let* ((l (string-tokenize-by-char x #\space))
                (r (list-intersperse l '(nbsp))))
           (apply tmconcat r)))
        (else x)))

(tm-define (bib-name-ends? x s)
  (cond ((tm-func? x 'concat) (bib-name-ends? (cAr x) s))
        ((string? x) (string-ends? x s))
        (else #f)))

(tm-define (bib-format-first-name x)
  (if (bib-null? (list-ref x 1)) ""
      (with f (bib-non-breaking (list-ref x 1))
        (if (bib-name-ends? f ".")
            (tmconcat f '(nbsp))
            (tmconcat f " ")))))

(tm-define (bib-format-name x)
  ;; (:mode bib-plain?)
  (let* ((ff (bib-format-first-name x))
         (vv (if (bib-null? (list-ref x 2)) ""
                 `(concat ,(list-ref x 2) (nbsp))))
         (ll (if (bib-null? (list-ref x 3)) ""
                 (bib-purify (list-ref x 3))))
         (jj (if (bib-null? (list-ref x 4)) ""
                 `(concat ", " ,(list-ref x 4)))))
    `(concat ,ff ,vv ,ll ,jj)))

(define (bib-format-names-rec n lim a)
  (if (equal? n lim)
      ""
      `(concat ", "
               ,(bib-format-name (list-ref a n))
               ,(bib-format-names-rec (+ n 1) lim a))))

(tm-define (bib-last-name-sep a)
  ;; (:mode bib-plain?)
  (if (<= (length a) 3)
      (bib-translate " and ")
      (bib-translate ", and ")))

(tm-define (bib-format-names a)
  ;; (:mode bib-plain?)
  (if (or (bib-null? a) (nlist? a))
      ""
      (let* ((n (length a)))
        (if (equal? n 2)
            (bib-format-name (list-ref a 1))
            (let* ((b (bib-format-name (list-ref a 1)))
                   (m (bib-format-names-rec 2 (- n 1) a))
                   (e (if (or (== (list-ref (list-ref a (- n 1)) 3) "others")
                              (== (list-ref (list-ref a (- n 1)) 4) "others"))
                          `(concat " et" (nbsp) "al")
                          `(concat ,(bib-last-name-sep a)
                                   ,(bib-format-name (list-ref a (- n 1)))))))
              `(concat ,b ,m ,e))))))

(tm-define (bib-format-author x)
  ;; (:mode bib-plain?)
  (with a (bib-field x "author")
    (if (bib-null? a)
        ""
        (bib-format-names a))))

(tm-define (bib-format-editor x)
  ;; (:mode bib-plain?)
  (with a (bib-field x "editor")
    (if (or (bib-null? a) (nlist? a))
        ""
        (if (equal? (length a) 2)
            `(concat ,(bib-format-names a) ,(bib-translate ", editor"))
            `(concat ,(bib-format-names a) ,(bib-translate ", editors"))))))

(tm-define (bib-format-in-ed-booktitle x)
  ;; (:mode bib-plain?)
  (let* ((b (bib-default-field x "booktitle"))
         (e (bib-field x "editor")))
    (if (bib-null? b)
        ""
        (if (bib-null? e)
            `(concat ,(bib-translate "in ") (with "font-shape" "italic" ,b))
            `(concat ,(bib-translate "in ") ,(bib-format-editor x) ", "
                     (with "font-shape" "italic" ,b))))))

(tm-define (bib-format-bvolume x)
  ;; (:mode bib-plain?)
  (let* ((v (bib-field x "volume"))
         (s (bib-default-field x "series")))
    (if (bib-null? v)
        ""
        (let ((series (if (bib-null? s) ""
                          `(concat ,(bib-translate " of ")
                                   (with "font-shape" "italic" ,s))))
              (sep (if (< (bib-text-length v) 3) `(nbsp) " ")))
          `(concat ,(bib-translate "volume") ,sep ,v ,series)))))

(tm-define (bib-format-number-series x)
  ;; (:mode bib-plain?)
  (let* ((v (bib-field x "volume"))
         (n (bib-field x "number"))
         (s (bib-default-field x "series")))
    (if (bib-null? v)
        (if (bib-null? n)
            (if (bib-null? s) "" s)
            (let ((series (if (bib-null? s) ""
                              `(concat ,(bib-translate " in ") ,s)))
                  (sep (if (< (bib-text-length n) 3) `(nbsp) " ")))
              `(concat ,(bib-translate "number") ,sep ,n ,series)))
        "")))

(tm-define (bib-format-pages x)
  ;; (:mode bib-plain?)
  (with p (bib-field x "pages")
    (cond
      ((or (bib-null? p) (nlist? p)) "")
      ((== (length p) 1) "")
      ((== (length p) 2)
       `(concat ,(bib-translate "page ") ,(list-ref p 1)))
      (else
        `(concat ,(bib-translate "pages ")
                 ,(list-ref p 1) ,bib-range-symbol ,(list-ref p 2))))))

(tm-define (bib-format-chapter-pages x)
  ;; (:mode bib-plain?)
  (let* ((c (bib-field x "chapter"))
         (t (bib-field x "type")))
    (if (bib-null? c)
        (bib-format-pages x)
        (let ((type (if (bib-null? t)
                        (bib-translate "chapter")
                        (bib-locase t)))
              (pages `(concat ", " ,(bib-format-pages x))))
          `(concat ,type " " ,c ,pages)))))

(tm-define (bib-format-vol-num-pages x)
  ;; (:mode bib-plain?)
  (let* ((v (bib-field x "volume"))
         (n (bib-field x "number"))
         (p (bib-field x "pages"))
         (vol (if (bib-null? v) "" v))
         (num (if (bib-null? n) "" `(concat "(" ,n ")")))
         (pag (if (or (bib-null? p) (nlist? p))
                  ""
                  (cond
                    ((equal? 1 (length p)) "")
                    ((equal? 2 (length p)) `(concat ":" ,(list-ref p 1)))
                    (else
                      `(concat ":" ,(list-ref p 1)
                               ,bib-range-symbol ,(list-ref p 2)))))))
    (if (and (== vol "") (== num ""))
        (bib-format-pages x)
        `(concat ,vol ,num ,pag))))

(tm-define (bib-format-date x)
  ;; (:mode bib-plain?)
  (let* ((y (bib-field x "year"))
         (m (bib-field x "month")))
    (if (bib-null? y)
        (if (bib-null? m) "" m)
        (if (bib-null? m) y `(concat ,m " " ,y)))))

(tm-define (bib-format-tr-number x)
  ;; (:mode bib-plain?)
  (let* ((t (bib-field x "type"))
         (n (bib-field x "number"))
         (type (if (bib-null? t) (bib-translate "Technical Report") t))
         (number (if (bib-null? n) "" n))
         (sep (if (< (bib-text-length n) 3) `(nbsp) " ")))
    (if (bib-null? n) type
        `(concat ,type ,sep ,number))))

(tm-define (bib-format-bibitem n x)
  ;; (:mode bib-plain?)
  `(bibitem* ,(number->string n)))

(tm-define (bib-format-article n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-format-field-Locase x "title"))
         ,(bib-new-block
           (if (bib-empty? x "crossref")
               (bib-new-sentence
                `(,(bib-emphasize (bib-format-field x "journal"))
                  ,(bib-format-vol-num-pages x)
                  ,(bib-format-date x)))
               (bib-new-sentence
                `((concat ,(bib-translate "in ")
                          (cite ,(bib-field x "crossref")))
                  ,(bib-format-pages x)))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-book n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block
           (if (bib-empty? x "author")
               (bib-format-editor x)
               (bib-format-author x)))
         ,(bib-new-block
           (bib-new-sentence
            `(,(bib-emphasize (bib-format-field x "title"))
              ,(bib-format-bvolume x))))
         ,(bib-new-block
           (if (bib-empty? x "crossref")
               (bib-new-list-spc
                `(,(bib-new-sentence
                    `(,(bib-format-number-series x)))
                  ,(bib-new-sentence
                    `(,(bib-format-field x "publisher")
                      ,(bib-format-field x "address")
                      ,(if (bib-empty? x "edition") ""
                           `(concat ,(bib-format-field x "edition")
                                    ,(bib-translate " edition")))
                      ,(bib-format-date x)))))
               (bib-new-sentence
                `((concat ,(bib-translate "in ")
                          (cite ,(bib-field x "crossref")))
                  ,(bib-format-field x "edition")
                  ,(bib-format-date x)))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-booklet n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-format-field-Locase x "title"))
         ,(bib-new-case-preserved-block
           (bib-new-case-preserved-sentence
            `(,(bib-format-field-preserve-case x "howpublished")
              ,(bib-upcase-first (bib-format-field x "address"))
              ,(bib-format-date x))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-inbook n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (if (bib-empty? x "author") (bib-format-editor x)
                         (bib-format-author x)))
         ,(bib-new-block
           (bib-new-sentence
            `(,(bib-emphasize (bib-format-field x "title"))
              ,(bib-format-bvolume x)
              ,(bib-format-chapter-pages x))))
         ,(bib-new-block
           (if (bib-empty? x "crossref")
               (bib-new-list-spc
                `(,(bib-new-sentence `(,(bib-format-number-series x)))
                  ,(bib-new-sentence
                    `(,(bib-format-field x "publisher")
                      ,(bib-format-field x "address")
                      ,(if (bib-empty? x "edition") ""
                           `(concat ,(bib-format-field x "edition")
                                    ,(bib-translate " edition")))
                      ,(bib-format-date x)))))
               (bib-new-sentence
                `(,(bib-format-chapter-pages x)
                  (concat ,(bib-translate "in ")
                          (cite ,(bib-field x "crossref")))))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-incollection n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-format-field-Locase x "title"))
         ,(bib-new-block
           (if (bib-empty? x "crossref")
               (bib-new-list-spc
                `(,(bib-new-sentence
                    `(,(bib-format-in-ed-booktitle x)
                      ,(bib-format-bvolume x)
                      ,(bib-format-number-series x)
                      ,(bib-format-chapter-pages x)))
                  ,(bib-new-sentence
                    `(,(bib-format-field x "publisher")
                      ,(bib-format-field x "address")
                      ,(bib-format-date x)))))
               (bib-new-sentence
                `((concat ,(bib-translate "in ")
                          (cite ,(bib-field x "crossref")))
                  ,(bib-format-chapter-pages x)))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-inproceedings n x)
  ;; (:mode bib-plain?)
  `(concat
    ,(bib-format-bibitem n x)
    ,(bib-label (list-ref x 2))
    ,(bib-new-list-spc
      `(,(bib-new-block (bib-format-author x))
        ,(bib-new-block (bib-format-field-Locase x "title"))
        ,(bib-new-block
          (if (bib-empty? x "crossref")
              (bib-new-list-spc
               `(,(bib-new-sentence
                   `(,(bib-format-in-ed-booktitle x)
                     ,(bib-format-bvolume x)
                     ,(bib-format-number-series x)
                     ,(bib-format-pages x)))
                 ,(if (bib-empty? x "address")
                      (bib-new-sentence
                       `(,(bib-format-field x "organization")
                         ,(bib-format-field x "publisher")
                         ,(bib-format-date x)))
                      (bib-new-list-spc
                       `(,(bib-new-sentence
                           `(,(bib-format-field x "address")
                             ,(bib-format-date x)))
                         ,(bib-new-sentence
                           `(,(bib-format-field x "organization")
                             ,(bib-format-field x "publisher"))))))))
              (bib-new-sentence
               `((concat ,(bib-translate "in ")
                         (cite ,(bib-field x "crossref")))
                 ,(bib-format-pages x)))))
        ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-manual n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block
           (if (bib-empty? x "author")
               (if (bib-empty? x "organization") ""
                   (bib-new-sentence
                    `(,(bib-format-field x "organization")
                      ,(bib-format-field x "address"))))
               (bib-format-author x)))
         ,(bib-new-block (bib-emphasize (bib-format-field x "title")))
         ,(bib-new-block
           (bib-new-sentence
            `(,(bib-format-field x "organization")
              ,(bib-format-field x "address")
              ,(if (bib-empty? x "edition") ""
                   `(concat ,(bib-format-field x "edition")
                            ,(bib-translate " edition")))
              ,(bib-format-date x))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-mastersthesis n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-format-field-Locase x "title"))
         ,(bib-new-block
           (bib-new-sentence
            `(,(if (bib-empty? x "type")
                   (bib-translate "Master's thesis")
                   (bib-format-field-Locase x "type"))
              ,(bib-format-field x "school")
              ,(bib-format-field x "address")
              ,(bib-format-date x))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-misc n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-format-field-Locase x "title"))
         ,(bib-new-case-preserved-block
           (bib-new-case-preserved-sentence
            `(,(bib-format-field-preserve-case x "howpublished")
              ,(bib-format-date x))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-phdthesis n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-emphasize (bib-format-field x "title")))
         ,(bib-new-block
           (bib-new-sentence
            `(,(if (bib-empty? x "type")
                   (bib-translate "PhD thesis")
                   (bib-format-field-Locase x "type"))
              ,(bib-format-field x "school")
              ,(bib-format-field x "address")
              ,(bib-format-date x))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-proceedings n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block
           (if (bib-empty? x "editor")
               (bib-format-field x "organization")
               (bib-format-editor x)))
         ,(bib-new-block
           (bib-new-sentence
            `(,(bib-emphasize (bib-format-field x "title"))
              ,(bib-format-bvolume x)
              ,(bib-format-number-series x))))
         ,(bib-new-block
           (if (bib-empty? x "address")
               (bib-new-sentence
                `(,(if (bib-empty? x "editor") ""
                       (bib-format-field x "organization"))
                  ,(bib-format-field x "publisher")
                  ,(bib-format-date x)))
               (bib-new-list-spc
                `(,(bib-new-sentence
                    `(,(bib-format-field x "address")
                      ,(bib-format-date x)))
                  ,(bib-new-sentence
                    `(,(if (bib-empty? x "editor") ""
                           (bib-format-field x "organization"))
                      ,(bib-format-field x "publisher")))))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-techreport n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-format-field-Locase x "title"))
         ,(bib-new-block
           (bib-new-sentence
            `(,(bib-format-tr-number x)
              ,(bib-format-field x "institution")
              ,(bib-format-field x "address")
              ,(bib-format-date x))))
         ,(bib-new-block (bib-format-field x "note"))))))

(tm-define (bib-format-unpublished n x)
  ;; (:mode bib-plain?)
  `(concat
     ,(bib-format-bibitem n x)
     ,(bib-label (list-ref x 2))
     ,(bib-new-list-spc
       `(,(bib-new-block (bib-format-author x))
         ,(bib-new-block (bib-format-field-Locase x "title"))
         ,(bib-new-block
           (bib-new-sentence
            `(,(bib-format-field x "note")
              ,(bib-format-date x))))))))

(tm-define (bib-format-entry n x)
  ;; (:mode bib-plain?)
  (if (and (list? x) (func? x 'bib-entry)
           (= (length x) 4) (func? (list-ref x 3) 'document))
      (with doctype (list-ref x 1)
        (cond
          ((equal? doctype "article") (bib-format-article n x))
          ((equal? doctype "book") (bib-format-book n x))
          ((equal? doctype "booklet") (bib-format-booklet n x))
          ((equal? doctype "inbook") (bib-format-inbook n x))
          ((equal? doctype "incollection") (bib-format-incollection n x))
          ((equal? doctype "inproceedings") (bib-format-inproceedings n x))
          ((equal? doctype "conference") (bib-format-inproceedings n x))
          ((equal? doctype "manual") (bib-format-manual n x))
          ((equal? doctype "mastersthesis") (bib-format-mastersthesis n x))
          ((equal? doctype "misc") (bib-format-misc n x))
          ((equal? doctype "phdthesis") (bib-format-phdthesis n x))
          ((equal? doctype "proceedings") (bib-format-proceedings n x))
          ((equal? doctype "techreport") (bib-format-techreport n x))
          ((equal? doctype "unpublished") (bib-format-unpublished n x))
          (else (bib-format-misc n x))))))

(define (author-sort-format a)
  (if (or (npair? a) (null? a))
      ""
      (with name
          (let* ((x (car a))
                 (ff (if (equal? (list-ref x 1) "") ""
                         (string-append (bib-purify (list-ref x 1)) " ")))
                 (vv (if (equal? (list-ref x 2) "") ""
                         (string-append (bib-purify (list-ref x 2)) " ")))
                 (ll (if (equal? (list-ref x 3) "") ""
                         (string-append (bib-purify (list-ref x 3)) " ")))
                 (jj (if (equal? (list-ref x 4) "") ""
                         (string-append (bib-purify (list-ref x 4)) " "))))
            (string-append vv ll ff jj))
        (string-append name (author-sort-format (bib-cdr a))))))

(define (author-editor-sort-key x)
  (if (bib-empty? x "author")
      (if (bib-empty? x "editor")
          (list-ref x 2)
          (string-upcase (author-sort-format
                          (bib-cdr (bib-field x "editor")))))
      (string-upcase (author-sort-format
                      (bib-cdr (bib-field x "author"))))))

(define (author-sort-key x ae)
  (if (bib-empty? x ae)
      (list-ref x 2)
      ;;(author-sort-format (bib-cdr (bib-field x ae)))))
      (string-upcase (author-sort-format (bib-cdr (bib-field x ae))))))

(tm-define (bib-sort-key x)
  ;; (:mode bib-plain?)
  (let* ((doctype (list-ref x 1))
         (pre (cond
                ((or (equal? doctype "inbook") (equal? doctype "book"))
                 (author-editor-sort-key x))
                ((equal? doctype "proceedings")
                 (author-sort-key x "editor"))
                (else
                  (author-sort-key x "author")))))
    (string-append pre "    "
                   (if (bib-empty? x "year") "" (string-append (bib-field x "year") "    "))
                   (bib-purify (bib-field x "title")))))

