(require 'pyim-sdk)

;; Pyim 词库缓存文件，注意：变量名称中不能出现 ":" 等，不能作为文件名称的字符。
(defvar pyim-dcache-code2word nil)
(defvar pyim-dcache-code2word-md5 nil)
(defvar pyim-dcache-word2code nil)
(defvar pyim-dcache-shortcode2word nil)
(defvar pyim-dcache-icode2word nil)
(defvar pyim-dcache-ishortcode2word nil)
(defvar pyim-dcache-update:shortcode2word nil)
(defvar pyim-dcache-update:ishortcode2word nil)
(defvar pyim-dcache-update:icode2word-p nil)

(defun pyim-dcache-get-value-from-file (file)
  "读取保存到 FILE 里面的 value."
  (when (file-exists-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (eval (read (current-buffer))))))

(defun pyim-dcache-save-value-to-file (value file)
  "将 VALUE 保存到 FILE 文件中."
  (when value
    (with-temp-buffer
      (insert ";; Auto generated by `pyim-dcache-save-variable-to-file', don't edit it by hand!\n")
      (insert (format ";; Build time: %s\n\n" (current-time-string)))
      (insert (prin1-to-string value))
      (insert "\n\n")
      (insert ";; Local Variables:\n")
      (insert ";; coding: utf-8-unix\n")
      (insert ";; End:")
      (make-directory (file-name-directory file) t)
      (let ((save-silently t))
        (pyim--write-file file)))))

(defun pyim-dcache-save-variable (variable)
  "将 VARIABLE 变量的取值保存到 `pyim-hashtable-directory' 中对应文件中."
  (let ((file (concat (file-name-as-directory pyim-hashtable-directory)
                      (symbol-name variable)))
        (value (symbol-value variable)))
    (pyim-dcache-save-value-to-file value file)))

(defun pyim-dcache-sort-words (words-list)
  "对 WORDS-LIST 排序，词频大的排在前面.

排序使用 `pyim-dcache-iword2count' 中记录的词频信息"
  (sort words-list
        #'(lambda (a b)
            (let ((a (car (split-string a ":")))
                  (b (car (split-string b ":"))))
              (> (or (gethash a pyim-iword2count) 0)
                 (or (gethash b pyim-iword2count) 0))))))

(defun pyim-dcache-return-shortcode (code)
  "获取一个 CODE 的所有简写.

比如：.nihao -> .nihao .niha .nih .ni .n"
  (when (and (> (length code) 0)
             (not (string-match-p "-" code))
             (pyim-string-match-p "^[[:punct:]]" code))
    (let* ((code1 (substring code 1))
           (prefix (substring code 0 1))
           (n (length code1))
           results)
      (dotimes (i n)
        (when (> i 1)
          (push (concat prefix (substring code1 0 i)) results)))
      results)))

(defun pyim-dcache-update:ishortcode2word (&optional force)
  "读取 ‘pyim-dcache-icode2word’ 中的词库，创建 *简拼* 缓存，然后加载这个缓存.
如果 `pyim-backend' 为 pyim-dregcache, 此函数不需要调用.

如果 FORCE 为真，强制加载缓存。"
  (interactive)
  (when (or force (not pyim-dcache-update:ishortcode2word))
    (if (pyim-use-emacs-thread-p)
        (make-thread
         `(lambda ()
            (maphash
             #'(lambda (key value)
                 (let ((newkey (mapconcat
                                #'(lambda (x)
                                    (substring x 0 1))
                                (split-string key "-") "-")))
                   (puthash newkey
                            (delete-dups
                             `(,@value
                               ,@(gethash newkey pyim-dcache-ishortcode2word)))
                            pyim-dcache-ishortcode2word)))
             pyim-dcache-icode2word)
            (maphash
             #'(lambda (key value)
                 (puthash key (pyim-dcache-sort-words value)
                          pyim-dcache-ishortcode2word))
             pyim-dcache-ishortcode2word)
            (pyim-dcache-save-variable 'pyim-dcache-ishortcode2word)
            (setq pyim-dcache-update:ishortcode2word t)))
      (async-start
       `(lambda ()
          ,(async-inject-variables "^load-path$")
          ,(async-inject-variables "^exec-path$")
          ,(async-inject-variables "^pyim-.+?directory$")
          (require 'pyim)
          (pyim-hashtable-set-variable 'pyim-dcache-icode2word)
          (pyim-hashtable-set-variable 'pyim-iword2count)
          (setq pyim-dcache-ishortcode2word
                (make-hash-table :test #'equal))
          (maphash
           #'(lambda (key value)
               (let ((newkey (mapconcat
                              #'(lambda (x)
                                  (substring x 0 1))
                              (split-string key "-") "-")))
                 (puthash newkey
                          (delete-dups
                           `(,@value
                             ,@(gethash newkey pyim-dcache-ishortcode2word)))
                          pyim-dcache-ishortcode2word)))
           pyim-dcache-icode2word)
          (maphash
           #'(lambda (key value)
               (puthash key (pyim-dcache-sort-words value)
                        pyim-dcache-ishortcode2word))
           pyim-dcache-ishortcode2word)
          (pyim-dcache-save-variable 'pyim-dcache-ishortcode2word))
       `(lambda (result)
          (setq pyim-dcache-update:ishortcode2word t)
          (pyim-hashtable-set-variable 'pyim-dcache-ishortcode2word t))))))

(defun pyim-dcache-update:shortcode2word (&optional force)
  "使用 `pyim-dcache-code2word' 中的词条，创建简写 code 词库缓存并加载.

如果 FORCE 为真，强制运行。"
  (interactive)
  (when (or force (not pyim-dcache-update:shortcode2word))
    (if (pyim-use-emacs-thread-p)
        (make-thread
         `(lambda ()
            (maphash
             #'(lambda (key value)
                 (dolist (x (pyim-dcache-return-shortcode key))
                   (puthash x
                            (mapcar
                             #'(lambda (word)
                                 (if (string-match-p ":"  word)
                                     word
                                   (concat word ":" (substring key (length x)))))
                             (delete-dups `(,@value ,@(gethash x pyim-dcache-shortcode2word))))
                            pyim-dcache-shortcode2word)))
             pyim-dcache-code2word)
            (maphash
             #'(lambda (key value)
                 (puthash key (pyim-dcache-sort-words value)
                          pyim-dcache-shortcode2word))
             pyim-dcache-shortcode2word)
            (pyim-dcache-save-variable 'pyim-dcache-shortcode2word)
            (setq pyim-dcache-update:shortcode2word t)))
      (async-start
       `(lambda ()
          ,(async-inject-variables "^load-path$")
          ,(async-inject-variables "^exec-path$")
          ,(async-inject-variables "^pyim-.+?directory$")
          (require 'pyim)
          (pyim-hashtable-set-variable 'pyim-dcache-code2word)
          (pyim-hashtable-set-variable 'pyim-iword2count)
          (setq pyim-dcache-shortcode2word
                (make-hash-table :test #'equal))
          (maphash
           #'(lambda (key value)
               (dolist (x (pyim-dcache-return-shortcode key))
                 (puthash x
                          (mapcar
                           #'(lambda (word)
                               ;; 这个地方的代码用于实现五笔 code 自动提示功能，
                               ;; 比如输入 'aa' 后得到选词框：
                               ;; ----------------------
                               ;; | 1. 莁aa 2.匶wv ... |
                               ;; ----------------------
                               (if (string-match-p ":"  word)
                                   word
                                 (concat word ":" (substring key (length x)))))
                           (delete-dups `(,@value ,@(gethash x pyim-dcache-shortcode2word))))
                          pyim-dcache-shortcode2word)))
           pyim-dcache-code2word)
          (maphash
           #'(lambda (key value)
               (puthash key (pyim-dcache-sort-words value)
                        pyim-dcache-shortcode2word))
           pyim-dcache-shortcode2word)
          (pyim-dcache-save-variable 'pyim-dcache-shortcode2word)
          nil)
       `(lambda (result)
          (setq pyim-dcache-update:shortcode2word t)
          (pyim-hashtable-set-variable 'pyim-dcache-shortcode2word t))))))

(defun pyim-dcache-get-path (variable)
  "获取保存 VARIABLE 取值的文件的路径."
  (when (symbolp variable)
    (concat (file-name-as-directory pyim-hashtable-directory)
            (symbol-name variable))))

(defun pyim-dcache-generate-dcache-file (dict-files dcache-file)
  "读取词库文件列表：DICT-FILES, 生成一个词库缓冲文件 DCACHE-FILE.

pyim 使用的词库文件是简单的文本文件，编码 *强制* 为 'utf-8-unix,
其结构类似：

  ni-bu-hao 你不好
  ni-hao  你好 妮好 你豪

第一个空白字符之前的内容为 code，空白字符之后为中文词条列表。词库
*不处理* 中文标点符号。"
  (let ((hashtable (make-hash-table :size 1000000 :test #'equal)))
    (dolist (file dict-files)
      (with-temp-buffer
        (let ((coding-system-for-read 'utf-8-unix))
          (insert-file-contents file))
        (goto-char (point-min))
        (forward-line 1)
        (while (not (eobp))
          (let* ((content (pyim-dline-parse))
                 (code (car content))
                 (words (cdr content)))
            (when (and code words)
              (puthash code
                       (delete-dups `(,@(gethash code hashtable) ,@words))
                       hashtable)))
          (forward-line 1))))
    (pyim-dcache-save-value-to-file hashtable dcache-file)
    hashtable))

(defun pyim-dcache-generate-word2code-dcache-file (dcache file)
  "从 DCACHE 生成一个 word -> code 的反向查询表.
DCACHE 是一个 code -> words 的 hashtable.
并将生成的表保存到 FILE 中."
  (when (hash-table-p dcache)
    (let ((hashtable (make-hash-table :size 1000000 :test #'equal)))
      (maphash
       #'(lambda (code words)
           (unless (pyim-string-match-p "-" code)
             (dolist (word words)
               (let ((value (gethash word hashtable)))
                 (puthash word
                          (if value
                              `(,code ,@value)
                            (list code))
                          hashtable)))))
       dcache)
      (pyim-dcache-save-value-to-file hashtable file))))

(defun pyim-dcache-update:code2word (dict-files dicts-md5 &optional force)
  "读取并加载词库.

读取 `pyim-dicts' 和 `pyim-extra-dicts' 里面的词库文件，生成对应的
词库缓冲文件，然后加载词库缓存。

如果 FORCE 为真，强制加载。"
  (interactive)
  (let* ((code2word-file (pyim-dcache-get-path 'pyim-dcache-code2word))
         (word2code-file (pyim-dcache-get-path 'pyim-dcache-word2code))
         (code2word-md5-file (pyim-dcache-get-path 'pyim-dcache-code2word-md5)))
    (when (or force (not (equal dicts-md5 (pyim-dcache-get-value-from-file code2word-md5-file))))
      ;; use hashtable
      (if (pyim-use-emacs-thread-p)
          (make-thread
           `(lambda ()
              (let ((dcache (pyim-dcache-generate-dcache-file ',dict-files ,code2word-file)))
                (pyim-dcache-generate-word2code-dcache-file dcache ,word2code-file))
              (pyim-dcache-save-value-to-file ',dicts-md5 ,code2word-md5-file)
              (pyim-hashtable-set-variable 'pyim-dcache-code2word t)
              (pyim-hashtable-set-variable 'pyim-dcache-word2code t)))
        (async-start
         `(lambda ()
            ,(async-inject-variables "^load-path$")
            ,(async-inject-variables "^exec-path$")
            ,(async-inject-variables "^pyim-.+?directory$")
            (require 'pyim)
            (let ((dcache (pyim-dcache-generate-dcache-file ',dict-files ,code2word-file)))
              (pyim-dcache-generate-word2code-dcache-file dcache ,word2code-file))
            (pyim-dcache-save-value-to-file ',dicts-md5 ,code2word-md5-file))
         `(lambda (result)
            (pyim-hashtable-set-variable 'pyim-dcache-code2word t)
            (pyim-hashtable-set-variable 'pyim-dcache-word2code t)))))))

(defun pyim-dcache-export (file &optional confirm)
  "将 `pyim-dregcache-icode2word' 导出为文件 FILE.

如果 CONFIRM 为 non-nil，文件存在时将会提示用户是否覆盖，
默认为覆盖模式"
  (with-temp-buffer
    (insert ";;; -*- coding: utf-8-unix -*-\n")
    (dolist (elem pyim-dregcache-icode2word)
      (insert (format "%s %s\n" (car elem) (cdr-elem))))
    (pyim--write-file file confirm)))

(defun pyim-dcache-export-personal-dcache (file &optional confirm)
  "将用户选择过的词生成的缓存导出为 pyim 词库文件.

如果 FILE 为 nil, 提示用户指定导出文件位置, 如果 CONFIRM 为 non-nil，
文件存在时将会提示用户是否覆盖，默认为覆盖模式。

注： 这个函数的用途是制作 pyim 词库，个人词条导入导出建议使用：
`pyim-import' 和 `pyim-export' ."
  (interactive "F将个人缓存中的词条导出到文件：")
  (cond
   ((eq pyim-backend 'pyim-dregcache)
    (pyim-dregcache-export file confirm))
   (t
    (pyim-dcache-export pyim-dcache-icode2word file confirm))))

(defun pyim-dcache-export (dcache file &optional confirm)
  "将一个 pyim DCACHE 导出为文件 FILE.

如果 CONFIRM 为 non-nil，文件存在时将会提示用户是否覆盖，
默认为覆盖模式"
  (with-temp-buffer
    (insert ";;; -*- coding: utf-8-unix -*-\n")
    (maphash
     #'(lambda (key value)
         (insert (format "%s %s\n"
                         key
                         (if (listp value)
                             (mapconcat #'identity value " ")
                           value))))
     dcache)
    (pyim--write-file file confirm)))

(defun pyim-dcache-get (code dcache-list)
  "从 DCACHE-LIST 包含的所有 dcache 中搜索 CODE, 得到对应的词条.

当词库文件加载完成后，pyim 就可以用这个函数从词库缓存中搜索某个
code 对应的中文词条了。

如果 DCACHE-LIST 为 nil, 则默认搜索 `pyim-dcache-icode2word' 和
`pyim-dcache-code2word' 两个 dcache."
  (let (result)
    (dolist (cache dcache-list)
      (let ((value (and cache (gethash code cache))))
        (when value
          (setq result (append result value)))))
    `(,@result ,@(pyim-pinyin2cchar-get code t t))))

(defun pyim-dcache-update:icode2word (&optional force)
  "对 personal 缓存中的词条进行排序，加载排序后的结果.

在这个过程中使用了 `pyim-dcache-iword2count' 中记录的词频信息。
如果 FORCE 为真，强制排序。"
  (interactive)
  (when (or force (not pyim-dcache-update:icode2word-p))
    (if (pyim-use-emacs-thread-p)
        (make-thread
         `(lambda ()
            (maphash
             #'(lambda (key value)
                 (puthash key (pyim-dcache-sort-words value)
                          pyim-dcache-icode2word))
             pyim-dcache-icode2word)
              (pyim-dcache-save-variable 'pyim-dcache-icode2word)
            (setq pyim-dcache-update:icode2word-p t)))
      (async-start
       `(lambda ()
          ,(async-inject-variables "^load-path$")
          ,(async-inject-variables "^exec-path$")
          ,(async-inject-variables "^pyim-.+?directory$")
          (require 'pyim)
          (pyim-hashtable-set-variable 'pyim-dcache-icode2word)
          (pyim-hashtable-set-variable 'pyim-iword2count)
          (maphash
           #'(lambda (key value)
               (puthash key (pyim-dcache-sort-words value)
                        pyim-dcache-icode2word))
           pyim-dcache-icode2word)
          (pyim-dcache-save-variable 'pyim-dcache-icode2word)
          nil)
       `(lambda (result)
          (setq pyim-dcache-update:icode2word-p t)
           (unless (eq pyim-backend 'pyim-dregcache)
             (pyim-hashtable-set-variable 'pyim-dcache-icode2word t)))))))

(defun pyim-dcache-update-personal-words (&optional force)
  (pyim-dcache-update:icode2word force)
  (pyim-dcache-update:ishortcode2word force))

(provide 'pyim-dcache)
;;; pyim-dcache.el ends here