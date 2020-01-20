;; Useful note:
;; - https://people.umass.edu/weikaichen/post/emacs-academic-tools/
;; - https://www.anand-iyer.com/blog/2017/research-literature-management-with-emacs.html
;; - https://nasseralkmim.github.io/notes/2016/08/21/my-latex-environment/
;; - 

;; This is a temp fix for a bug in org-ref, which has been fixed but not make it to stable ver.
(require 'parsebib)
;; setting reftex
(setq reftex-default-bibliography '("~/Documents/refs/references.bib"))

;; key binding for ivy-bibtex, open notes.
(global-set-key (kbd "C-c C-r") 'ivy-bibtex)
(global-set-key (kbd "C-c C-i") 'org-ref-open-bibtex-notes)

;; see org-ref for use of these variables
(setq org-ref-bibliography-notes "~/Documents/refs/notes.org"
      org-ref-default-bibliography `("~/Documents/refs/references.bib")
      org-ref-pdf-directory "~/Documents/papers")

;; setting ivy-bibtex/helm-bibtex
(setq bibtex-completion-bibliography `("~/Documents/refs/references.bib"))

(setq bibtex-completion-library-path '("~/Documents/papers"))
(setq bibtex-completion-notes-path "~/Documents/refs/notes.org")

;; ignore ignores the order of regexp tokens when searching for matching candidates
(setq ivy-re-builders-alist
      '((ivy-bibtex . ivy--regex-ignore-order)
        (t . ivy--regex-plus)))

(setq bibtex-completion-pdf-open-function
  (lambda (fpath)
    (start-process "open" "*open*" "open" fpath)))

;; setting forend for completion of org-ref
(setq org-ref-completion-library 'org-ref-ivy-cite)
(require 'org-ref)

(setq org-latex-pdf-process (list "latexmk -shell-escape -bibtex -f -pdf %f"))

;; see https://github.com/tmalsburg/helm-bibtex
;; (setq bibtex-completion-additional-search-fields '(keywords))
(setq bibtex-completion-additional-search-fields '(journal booktitle))
;; display form of ivy-bibtex
(setq bibtex-completion-display-formats
    '((article       . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:15} ${title:*} ${journal:10}")
      (inbook        . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:15} ${title:*} Chapter ${chapter:10}")
      (incollection  . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:15} ${title:*} ${booktitle:10}")
      (inproceedings . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:15} ${title:*} ${booktitle:10}")
      (t             . "${=has-pdf=:1}${=has-note=:1} ${=type=:3} ${year:4} ${author:15} ${title:*}")))
;;symbols for display
(setq bibtex-completion-pdf-symbol "⌘")
(setq bibtex-completion-notes-symbol "✎")

;; Use pdf link for org citation
(setq bibtex-completion-format-citation-functions
  '((org-mode      . bibtex-completion-format-citation-org-link-to-PDF)
    (latex-mode    . bibtex-completion-format-citation-cite)
    (markdown-mode . bibtex-completion-format-citation-pandoc-citeproc)
    (default       . bibtex-completion-format-citation-default)))

(setq org-ref-completion-library 'org-ref-ivy-cite)
;;(setq ivy-bibtex-default-action 'bibtex-completion-insert-citation)

(provide 'init-refs)