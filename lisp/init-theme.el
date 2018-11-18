;; still in favour of black theme :>
(defun load-daemon-theme (frame)
  (select-frame frame)
  (load-theme 'molokai t))

(if (daemonp)
	(add-hook 'after-make-frame-functions #'load-daemon-theme)
  (load-theme 'molokai t))

(provide 'init-theme)