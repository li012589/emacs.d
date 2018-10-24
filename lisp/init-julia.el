(setenv "JULIA_NUM_THREADS" "4")

(add-hook 'julia-mode-hook 'julia-repl-mode)

(provide 'init-julia)