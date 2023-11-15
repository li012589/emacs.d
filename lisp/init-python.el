;; -*- coding: utf-8; lexical-binding: t; -*-

(with-eval-after-load 'python
  ;; run command `pip install jedi flake8 importmagic` in shell,
  ;; or just check https://github.com/jorgenschaefer/elpy
  (unless (or (my-buffer-file-temp-p)
              (not buffer-file-name)
              ;; embed python code in org file
              (string= (file-name-extension buffer-file-name) "org"))
    (setq elpy-shell-command-prefix-key "C-c C-f")
    (elpy-enable)
    ;; If you don't like any hint or error report from elpy,
    ;; set `elpy-disable-backend-error-display' to t.
    (setq elpy-disable-backend-error-display t))
  ;; http://emacs.stackexchange.com/questions/3322/python-auto-indent-problem/3338#3338
  ;; emacs 24.4+
  (setq electric-indent-chars (delq ?: electric-indent-chars)))

;; add auto completion backend to company-mode
(defun company-anaconda-mode-setup ()
  (add-to-list 'company-backends 'company-anaconda))

(add-hook 'python-mode-hook 'anaconda-mode)
(add-hook 'python-mode-hook 'company-anaconda-mode-setup)

(provide 'init-python)
;;; init-python.el ends here
