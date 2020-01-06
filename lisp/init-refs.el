(setq bibPath '("~/Documents/refs/references.bib"))
(setq notePath '("~/Documents/refs/notes.org"))
(setq pdfPath '("~/Documents/papers"))

(setq reftex-default-bibliography 'bibPath)

;; see org-ref for use of these variables
(setq org-ref-bibliography-notes 'notePath
      org-ref-default-bibliography 'bibPath
      org-ref-pdf-directory 'pdfPath)

(setq bibtex-completion-bibliography 'bibPath)

(setq bibtex-completion-library-path 'pdfPath)
(setq bibtex-completion-notes-path 'notePath)

(setq bibtex-completion-pdf-open-function
  (lambda (fpath)
    (start-process "open" "*open*" "open" fpath)))

(setq org-latex-pdf-process (list "latexmk -shell-escape -bibtex -f -pdf %f"))

(setq bibtex-completion-display-formats
    '((article       . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} ${journal:40}")
      (inbook        . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} Chapter ${chapter:32}")
      (incollection  . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
      (inproceedings . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*} ${booktitle:40}")
      (t             . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:36} ${title:*}")))

;; (setq bibtex-completion-additional-search-fields '(keywords))

(setq org-ref-completion-library 'org-ref-ivy-cite)

(require 'doi-utils)
(require 'org-ref-arxiv)


(provide 'init-refs)