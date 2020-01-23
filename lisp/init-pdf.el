(pdf-tools-install)
;; See http://pragmaticemacs.com/emacs/more-pdf-tools-tweaks/ for some tips

;; turn off cua so copy works
(add-hook 'pdf-view-mode-hook (lambda () (cua-mode 0)))

;; open pdfs scaled to fit page
(setq-default pdf-view-display-size 'fit-page)
;;(setq pdf-view-resize-factor 1.1)

;; Add HiDPI support, see https://github.com/politza/pdf-tools/issues/51
(setq pdf-view-use-scaling t)

;; use normal isearch
(define-key pdf-view-mode-map (kbd "C-s") 'isearch-forward)

(provide 'init-pdf)
