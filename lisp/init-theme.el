;; still in favour of black theme :>
(when (or (display-graphic-p)
          (string-match-p "256color"(getenv "TERM")))
  (load-theme 'molokai t))

(provide 'init-theme)