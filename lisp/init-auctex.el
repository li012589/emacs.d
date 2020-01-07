(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)

;; Settings from https://nasseralkmim.github.io/notes/2016/08/21/my-latex-environment/
(add-hook 'LaTeX-mode-hook
            (lambda ()
              (rainbow-delimiters-mode)
              (company-mode)
              (smartparens-mode)
              (turn-on-reftex)
              (setq reftex-plug-into-AUCTeX t)
              (reftex-isearch-minor-mode)
              (setq TeX-PDF-mode t)
              (setq TeX-source-correlate-method 'synctex)
              (setq TeX-source-correlate-start-server t)))
;; Update PDF buffers after successful LaTeX runs
(add-hook 'TeX-after-TeX-LaTeX-command-finished-hook
           #'TeX-revert-document-buffer)

;; to use pdfview with auctex
(add-hook 'LaTeX-mode-hook 'pdf-tools-install)

;; to use pdfview with auctex
(setq TeX-view-program-selection '((output-pdf "pdf-tools"))
       TeX-source-correlate-start-server t)

(setq reftex-plug-into-AUCTeX t)
;; (setq preview-transparent-color 20)
(set-default 'preview-scale-function 1.5)

(custom-set-faces '(preview-reference-face ((t (:background "gray100")))))

;; Settings for Reftex
;; use RefTex
(add-hook 'LaTeX-mode-hook 'turn-on-reftex)   ; with AUCTeX LaTeX mode
(setq reftex-plug-into-AUCTeX t)

(setq reftex-cite-prompt-optional-args t); Prompt for empty optional arguments in cite

;;Settings for pdf-tools

(setq mouse-wheel-follow-mouse t)
(setq pdf-view-resize-factor 1.10)

(provide 'init-auctex)