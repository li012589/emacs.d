(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)

(setq reftex-plug-into-AUCTeX t)
;; (setq preview-transparent-color 20)
(set-default 'preview-scale-function 1.5)

(custom-set-faces '(preview-reference-face ((t (:background "gray100")))))

(provide 'init-auctex)