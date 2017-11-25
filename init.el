;; -*- lexical-binding: t -*-

(setq lexical-binding t)
(setq package-menu-async nil)

(eval-when-compile
  (require 'cl))
(require 'package)

(progn
  (add-to-list 'package-archives
               '("melpa" . "http://melpa.org/packages/"))
  (package-initialize)

  (when (not (package-installed-p 'req-package))
    (package-refresh-contents)
    (package-install 'req-package)))

(require 'req-package)


(defun juiko/python-find-env (project-root)
  "Find the python project env directory, inside PROJECT-ROOT."
  (car (-intersection (mapcar (lambda (path) (f-join project-root path))
                              (list "env" ".env"))
                      (f-directories project-root))))

(req-package pyvenv
  :require projectile
  :init (defvar *python-current-env* "")
  :config (eval-after-load "pyvenv"
            '(progn
               (add-hook 'python-mode-hook
                         (lambda ()
                           (let* ((root (projectile-project-root))
                                  (env (juiko/python-find-env root)))
                             (if (and env
                                      (not (equal env *python-current-env*)))
                                 (progn
                                   (setf *python-current-env* env)
                                   (pyvenv-activate env)
                                   (message "Current python env: %s" *python-current-env*))
                               (message "Did not set env to %s" env))))))))



(req-package irony
  :config (progn
            (add-hook 'c-mode-hook 'irony-mode)
            (add-hook 'c++-mode-hook 'irony-mode)
            (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)))

(req-package company-irony
  :require irony
  :config (progn
            (add-hook 'irony-mode-hook
                      (lambda ()
                        (setq-local company-backends '(company-irony))))))

(req-package flycheck-irony
  :config (add-hook 'flycheck-mode-hook 'flycheck-irony-setup))

(req-package irony-eldoc
  :config (progn
            (add-hook 'irony-mode-hook 'irony-eldoc)))

(req-package f
  )

(req-package bind-key
  :config (progn
            (bind-key (kbd "M--") 'hippie-expand)
            (bind-key (kbd "M-g M-g")
                      '(lambda ()
                         (interactive)
                         (unwind-protect
                             (progn
                               (linum-mode t)
                               (call-interactively 'goto-line))
                           (linum-mode -1))))))

(req-package iedit

  :require bind-key
  :config (progn
            (bind-key (kbd "C-%") 'iedit-mode)))

(req-package erc

  :commands (erc)
  :config (progn
            (setf erc-autojoin-channels-alist
                  '(("snoonet.org" "#syriancivilwar")
                    ("freenode.net" "#emacs" "#python" "#haskell")))))

(req-package company
  :config (progn
            (setf company-minimum-prefix-length 2)
            (setf company-show-numbers t)
            (setf company-idle-delay 1)
            (setf company-quickhelp-delay 1)
            (global-company-mode)

            (eval-after-load "cperl-mode"
              (add-hook 'cperl-mode-hook
                        (lambda ()
                          (make-variable-buffer-local 'company-backends)
                          (setq-local company-backends '((company-gtags
                                                          company-dabbrev
                                                          company-dabbrev-code))))))))

(req-package company-quickhelp
  :disabled t
  :if window-system
  :require company
  :config (add-hook 'company-mode-hook 'company-quickhelp-mode))

(req-package flycheck
  :config (progn
            (global-flycheck-mode)

            (setq flycheck-perlcritic-severity 5)
            (setq flycheck-ghc-args (list
                                     "-fwarn-tabs"
                                     "-fwarn-type-defaults"
                                     "-fwarn-unused-do-bind"
                                     "-fwarn-incomplete-uni-patterns"
                                     "-fwarn-incomplete-patterns"
                                     "-fwarn-incomplete-record-updates"
                                     "-fwarn-monomorphism-restriction"
                                     "-fwarn-auto-orphans"
                                     "-fwarn-implicit-prelude"
                                     "-fwarn-missing-exported-sigs"
                                     "-fwarn-identities"
                                     "-Wall"))

            (custom-set-faces
             '(flycheck-error ((t (:underline "Red1"))))
             '(flycheck-info ((t (:underline "ForestGreen"))))
             '(flycheck-warning ((t (:underline "DarkOrange"))))
             )

            (add-hook 'ruby-mode-hook
                      (flycheck-disable-checker 'ruby-rubylint nil))
            ))

(req-package flycheck-pos-tip
  :disabled t
  :if window-system
  :require flycheck
  :config (progn
            (setq flycheck-display-errors-function
                  #'flycheck-pos-tip-error-messages)))

(defvar *no-smartparens-list*
  '(haskell-mode))

(req-package smartparens
  :config (progn
            (sp-local-pair '(emacs-lisp-mode
                             lisp-mode
                             slime-repl-mode)
                           "`" nil :actions nil)
            (sp-local-pair '(emacs-lisp-mode
                             lisp-mode
                             slime-repl-mode)
                           "'" nil :actions nil)
            (add-to-list 'sp-no-reindent-after-kill-modes 'haskell-mode)

            (add-hook 'prog-mode-hook
                      (lambda ()
                        (unless (-contains? *no-smartparens-list* major-mode)
                          (smartparens-strict-mode))))

            (require 'smartparens-html)
            (require 'smartparens-rust)
            (require 'smartparens-python)
            (require 'smartparens-ruby)))

(req-package slime-company
  :require company)

(req-package slime
  :require slime-company
  :init (progn
          (setf inferior-lisp-program "sbcl")
          (setf slime-contrib '(slime-fancy slime-company))
          (setf slime-sbcl-manual-root "/usr/local/share/info/sbcl.info")
          (add-hook 'lisp-mode-hook
                    (lambda ()
                      (unless (slime-connected-p)
                        (save-excursion (slime))))))
  :config (progn
            (slime-setup '(slime-fancy slime-company))
            (cl-loop for hook in '(slime-mode-hook slime-repl-mode-hook)
                     do
                     (add-hook hook
                               (lambda ()
                                 (setq-local company-backends '(company-slime)))))))

(req-package evil
  :require bind-key
  :config (progn
            (bind-key "TAB" 'indent-region evil-visual-state-map)
            (bind-key "C-TAB" 'indent-whole-buffer evil-normal-state-map)
            (bind-key [return] (lambda ()
                                 (interactive)
                                 (save-excursion
                                   (newline)))
                      evil-normal-state-map)

            (setf evil-move-cursor-back nil)

            (cl-loop for mode in '(haskell-interactive-mode
                                   haskell-presentation-mode
                                   haskell-error-mode
                                   sql-interactive-mode
                                   inferior-emacs-lisp-mode
                                   erc-mode
                                   parparadox-menu-mode
                                   comint-mode
                                   eshell-mode
                                   slime-repl-mode
                                   slime-macroexpansion-minor-mode-hook
                                   geiser-repl-mode
                                   cider-repl-mode
                                   inferior-python-mode
                                   intero-repl-mode
                                   inf-ruby-mode
                                   magit-mode)
                     do (evil-set-initial-state mode 'emacs))


            (evil-mode)))


(req-package evil-lisp-state
  :require evil evil-leader bind-key
  :init (progn
          (setf evil-lisp-state-global t)
          (setf evil-lisp-state-enter-lisp-state-on-command nil))
  :config (progn
            (bind-key "L" 'evil-lisp-state evil-normal-state-map)
            ))

(req-package evil-smartparens
  :require evil smartparens
  :config (progn
            (add-hook 'smartparens-strict-mode-hook 'evil-smartparens-mode)))

(req-package evil-commentary
  :require evil
  :config (progn
            (evil-commentary-mode)
            ))

(req-package evil-god-state
  :require evil god-mode
  :config (progn
            (bind-key "ESC" 'evil-normal-state evil-god-state-map)))

(req-package evil-leader
  :require evil
  :config (progn
            (setf evil-leader/leader (kbd ","))
            (evil-leader/set-key
              "f" 'helm-find-files
              "b" 'switch-to-buffer
              "g" 'helm-M-x
              "k" 'kill-buffer
              "," 'evil-execute-in-emacs-state
              ";" 'comment-dwim
              "e" 'eval-last-sexp
              "w" 'save-buffer
              "." 'ggtags-find-tag-dwim
              "hs" 'helm-swoop
              "ha" 'helm-ag
              "hi" 'helm-semantic-or-imenu
              "hP"  'helm-projectile
              "hpa" 'helm-projectile-ag
              "ptp" 'projectile-test-project
              "mgb" 'magit-branch
              "mgc" 'magit-checkout
              "mgc" 'magit-checkout
              "mgl" 'magit-log
              "mgs" 'magit-status
              "mgpl" 'magit-pull
              "mgps" 'magit-push)

            (evil-leader/set-key-for-mode 'haskell-mode "H" 'haskell-hoogle)
            (evil-leader/set-key-for-mode 'emacs-lisp-mode "ma" 'pp-macroexpand-last-sexp)
            (evil-leader/set-key-for-mode 'lisp-interaction-mode "ma" 'pp-macroexpand-last-sexp)

            (evil-leader/set-key-for-mode 'lisp-mode "cl" 'slime-load-file)
            (evil-leader/set-key-for-mode 'lisp-mode "e" 'slime-eval-last-expression)
            (evil-leader/set-key-for-mode 'lisp-mode "me" 'slime-macroexpand-1)
            (evil-leader/set-key-for-mode 'lisp-mode "ma" 'slime-macroexpand-all)
            (evil-leader/set-key-for-mode 'lisp-mode "sds" 'slime-disassemble-symbol)
            (evil-leader/set-key-for-mode 'lisp-mode "sdd" 'slime-disassemble-definition)
            (evil-leader/set-key-for-mode 'cider-mode "e" 'cider-eval-last-sexp)
            (evil-leader/set-key-for-mode 'projectile-mode (kbd "p")'helm-projectile)
            (global-evil-leader-mode)))

(req-package evil-magit
  :require evil magit
  )

(req-package material-theme
  :if window-system
  :disabled t
  :config (progn
            (load-theme 'material-light t)

            (add-hook 'after-init-hook
                      (lambda ()
                        (set-face-attribute 'fringe
                                            nil
                                            :background "#FAFAFA"
                                            :foreground "#FAFAFA")))))

(req-package leuven-theme
  :disabled t
  :if window-system
  :config (progn
            (add-hook 'after-init-hook
                      (lambda ()
                        (load-theme 'leuven t)
                        (set-face-attribute 'fringe
                                            nil
                                            :background "2e3436"
                                            :foreground "2e3436")
                        ))))

(req-package projectile
  :config (progn
            (add-hook 'after-init-hook 'projectile-global-mode)))

(req-package helm-config
  :config (progn

            (bind-key "M-x" 'helm-M-x)
            (bind-key "C-x C-f" 'helm-find-files)

            (setf helm-split-window-in-side-p t)

            (add-to-list 'display-buffer-alist
                         '("\\`\\*helm.*\\*\\'"
                           (display-buffer-in-side-window)
                           (inhibit-same-window . t)
                           (window-height . 0.4)))

            (setf helm-swoop-split-with-multiple-windows nil
                  helm-swoop-split-direction 'split-window-vertically
                  helm-swoop-split-window-function 'helm-default-display-buffer)

            (helm-mode)))

(req-package helm-projectile
  :require helm projectile
  :config (progn
            (helm-projectile-on)))

(req-package helm-ag
  :require helm
  :commands (helm-ag))

(req-package helm-swoop
  :require helm
  :commands (helm-swoop))

(req-package helm-grep-ack
  :require helm
  :commands (helm-ack))

(req-package helm-gtags
  :require helm
  :config (add-hook 'prog-mode-hook 'helm-gtags-mode))

(req-package magit
  :init (progn
          (setf magit-last-seen-setup-instructions "1.4.0")))

(req-package haskell-mode
  :config (progn
            (add-hook 'haskell-mode-hook 'haskell-doc-mode)
            (add-hook 'haskell-mode-hook 'haskell-indentation-mode)
            ;; (add-hook 'haskell-mode-hook 'interactive-haskell-mode)
            (add-hook 'haskell-mode-hook 'haskell-decl-scan-mode)
            (add-hook 'haskell-mode-hook (lambda ()
                                           (electric-indent-local-mode -1)))

            (setf haskell-process-type 'stack-ghci)
            (setf haskell-process-path-ghci "stack")
            (setf haskell-process-args-ghci '("ghci "))

            (setf haskell-process-suggest-remove-import-lines t)
            (setf haskell-process-auto-import-loaded-modules t)
            (setf haskell-process-log nil)
            (setf haskell-stylish-on-save t)))


(req-package intero
  :require haskell-mode
  :config (progn
            (add-hook 'haskell-mode-hook 'intero-mode)
            (add-hook 'intero-mode-hook
                      (lambda ()
                        (progn
                          (make-variable-buffer-local 'company-backends)
                          (setq-local company-backends '(company-intero)))))))

(req-package hindent
  :require haskell-mode
  :config (progn
            (setf hindent-style "chris-done")
            (evil-define-key 'evil-visual-state hindent-mode-map "TAB"
              'hindent-reformat-region)
            (add-hook 'haskell-mode-hook 'hindent-mode)))

(req-package flycheck-haskell
  :require flycheck haskell-mode
  :disabled t
  :config (progn
            (add-hook 'haskell-mode-hook 'flycheck-mode)
            (add-hook 'flycheck-mode-hook 'flycheck-haskell-configure)))

(req-package company-ghci
  :disabled t
  :require company haskell-mode
  :config (progn
            (add-hook 'haskell-mode-hook
                      (lambda ()
                        (setq-local company-backends
                                    '((company-ghci
                                       company-dabbrev-code)))))))

(req-package hlint-refactor
  :require haskell-mode
  :config (progn
            (bind-key "C-c h r" 'hlint-refactor-refactor-at-point hlint-refactor-mode-map)

            (add-hook 'haskell-mode-hook 'hlint-refactor-mode)))

(req-package anaconda-mode
  :config (progn
            (add-hook 'python-mode-hook 'anaconda-mode)
            (add-hook 'python-mode-hook 'eldoc-mode)))

(req-package company-anaconda
  :require company anaconda-mode
  :config (progn
            (add-hook 'anaconda-mode-hook
                      (lambda ()
                        (make-variable-buffer-local 'company-backends)
                        (setq-local company-backends '(company-anaconda))))))

(req-package elpy
  :disabled t
  :config (progn
            (elpy-enable)))


(req-package pyvenv
  :config (progn
            (add-hook 'python-mode-hook 'pyvenv-mode)))

(req-package yasnippet
  :disabled t
  :config (progn
            (yas-reload-all)
            (add-hook 'python-mode-hook 'yas-minor-mode)
            (add-hook 'ruby-mode-hook 'yas-minor-mode)))



(req-package web-mode

  :config (progn
            (add-hook 'web-mode-hook #'turn-off-smartparens-mode)

            (add-hook 'web-mode-hook
                      (lambda ()
                        (setf web-mode-enable-auto-pairing t)
                        (setf web-mode-enable-css-colorization t)
                        (setf web-mode-enable-block-face t)
                        (setf web-mode-enable-heredoc-fontification t)
                        (setf web-mode-enable-current-element-highlight nil)
                        (setf web-mode-enable-current-column-highlight nil)
                        (setf web-mode-code-indent-offset 2)
                        (setf web-mode-markup-indent-offset 2)
                        (setf web-mode-css-indent-offset 2)))

            (cl-loop
             for extension in '("\\.blade\\.php\\'"
                                "\\.phtml\\'"
                                "\\.tpl\\.php\\'"
                                "\\.[agj]sp\\'"
                                "\\.as[cp]x\\'"
                                "\\.erb\\'"
                                "\\.mustache\\'"
                                "\\.djhtml\\'"
                                "\\.html\\'"
                                "\\html\\.twig\\'"
                                "\\html\\.jinja\\'"
                                "\\pdf\\.twig\\'")
             do (add-to-list 'auto-mode-alist `(,extension . web-mode)))))


(req-package php-mode

  :config (progn
            (require 'php-ext)
            (setf php-template-compatibility nil)
            (setf php-lineup-cascaded-calls t)
            (add-hook 'php-mode-hook
                      'php-enable-symfony2-coding-style)

            (add-hook 'php-mode-hook
                      (lambda ()
                        (setq-local company-backends '(company-gtags
                                                       company-dabbrev-code
                                                       ))))
            (with-eval-after-load "yasnippet"
              (add-hook 'php-mode-hook 'yas-minor-mode))))

(req-package php-eldoc
  :require php-mode
  :config (progn
            (add-hook 'php-mode-hook 'php-eldoc-enable)))

(req-package js2-mode

  :config (progn
            (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))))

(req-package rust-mode

  )

(req-package racer
  :require rust-mode company
  :config (progn
            (setf racer-cmd "/home/juiko/git/racer/target/release/racer")
            (setf racer-rust-src-path "/home/juiko/git/rust/src/")
            (add-hook 'rust-mode-hook 'racer-mode)
            (add-hook 'racer-mode-hook 'eldoc-mode)
            (evil-define-key 'evil-insert-state rust-mode-map (kbd "TAB") #'company-indent-or-complete-common)))

(req-package flycheck-rust
  :require rust-mode flycheck
  :config (progn
            (add-hook 'flycheck-mode-hook 'flycheck-rust-setup)))

(req-package elm-mode
  )

(req-package flycheck-elm
  :require elm-mode flycheck
  :config (progn
            (add-hook 'flycheck-mode-hook 'flycheck-elm-setup)))

(req-package color-theme-approximate
  :if (not window-system)
  :config (progn
            (color-theme-approximate-on)))


(req-package robe
  :config (progn
            (add-hook 'ruby-mode-hook 'robe-mode)
            (add-hook 'robe-mode-hook
                      (lambda ()
                        (make-variable-buffer-local 'company-backends)
                        (setq-local company-backends '(company-robe
                                                       company-dabbrev-code))))
            (add-hook 'robe-mode-hook 'eldoc-mode)))

(req-package rbenv
  :require robe
  :config (progn
            (global-rbenv-mode)))


(req-package projectile-rails
  :require projectile
  :config (progn
            (add-hook 'projectile-mode-hook 'projectile-rails-on)))

(req-package minitest

  :config (progn
            (add-hook 'ruby-mode-hook 'minitest-mode)))

(req-package cider

  :config (progn
            (add-hook 'clojure-mode-hook 'cider-mode)))


(req-package yaml-mode
  )

(req-package tide

  :config (progn
            (add-hook 'typescript-mode-hook  'tide-setup)
            ))

(req-package dumb-jump

  :config (progn
            (dumb-jump-mode)))

(req-package go-mode

  :config (progn
            (add-hook 'before-save-hook #'gofmt-before-save)))

(req-package go-eldoc
  :require go-mode
  :config (progn
            (add-hook go-mode-hook 'eldoc-mode)))

(req-package company-go
  :requires go-mode company
  :config (progn
            (add-hook go-mode-hook
                      (lambda ()
                        (make-variable-buffer-local 'company-backends)
                        (setq-local company-backends '(company-go))))))

(req-package counsel-etags

  :requires evil
  :config (progn
            (evil-define-key 'evil-emacs-state prog-mode-map (kbd"M-.") #'counsel-etags-find-tag-at-point)))

(req-package smart-mode-line
  :config (progn
            (setq sml/theme 'light)
            (sml/setup)))

(req-package-finish)

(use-package spacemacs-dark-theme
  :disabled t
  :load-path "/home/juiko/git/spacemacs-theme/")

(use-package tao-yang-theme
  :load-path "/home/juiko/git/tao-theme-emacs")

;;; Windows shut the fuck up,mgs
(setq ring-bell-function 'ignore)

(defvar *windows-subsystem-linux-p*
  (string-match-p "Microsoft"
                  (shell-command-to-string "uname -a")))

(defun juiko/compile-emacs-home ()
  (f-files "~/.emacs.d/"
           (lambda (f) (when (string-suffix-p ".el" f)
                         (byte-compile-file f)))
           t))

(defun juiko/look-config ()
  (blink-cursor-mode -1)
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (column-number-mode 1)
  (global-hl-line-mode 1)
  (show-paren-mode)
  (add-to-list 'default-frame-alist '(font . "DejaVu Sans Mono-9"))
  (add-to-list 'default-frame-alist '(cursor-color . "Gray")))


(add-hook 'inferior-python-mode-hook
          (lambda ()
            (python-shell-send-string "__name__ = None")))

(add-hook 'after-save-hook
          (lambda ()
            (when (eq major-mode 'python-mode)
              (let ((process (python-shell-get-process)))
                (when process
                  (python-shell-send-file (buffer-file-name (current-buffer))
                                          process))))))

(defun gtags-exists-p (root)
  (-contains-p  (f-files root)
                (f-join root "GTAGS")))

(defun async-gtags-create ()
  (call-process "gtags" nil 0 nil))

(defun async-gtags-update ()
  (call-process "global" nil 0 nil "-u"))

(defun async-gtags (root)
  (if (gtags-exists-p root)
      (async-gtags-update)
    (let ((default-directory root))
      (async-gtags-create))))

(setf *gtags-modes*
      '(web-mode
        php-mode
        cperl-mode
        ruby-mode
        ))

(defun endless/upgrade ()
  "Upgrade all packages, no questions asked."
  (interactive)
  (save-window-excursion
    (list-packages)
    (package-menu-mark-upgrades)
    (package-menu-execute 'no-query)))

(add-hook 'prog-mode-hook 'eldoc-mode)

(setq-default inhibit-startup-message t)
(fset 'yes-or-no-p 'y-or-n-p)

(setq-default backup-by-copying t      ; don't clobber symlinks
              backup-directory-alist '(("." . "~/.emacs.d/saves"))    ; don't litter my fs tree
              delete-old-versions t
              kept-new-versions 6
              kept-old-versions 2
              version-control t)

(add-hook 'after-save-hook
          (lambda ()
            (let ((init-file (expand-file-name "~/.emacs.d/init.el")))
              (when (equal (buffer-file-name) init-file)
                (byte-compile-file init-file)))))

(if *windows-subsystem-linux-p*
    (progn
      (setf browse-url-browser-function 'browse-url-chrome)
      (setf browse-url-chrome-program "/mnt/c/Program\ Files\ (x86)/Google/Chrome/Application/chrome.exe")))

(progn
  (defalias 'perl-mode 'cperl-mode)
  (setq-default cperl-electric-parens nil
                cperl-electric-keywords nil
                cperl-electric-lbrace-space nil))

(setf backup-directory-alist
      '((".*" . "/home/juiko/.emacs.d/cache/"))
      auto-save-file-name-transforms
      '((".*" "/home/juiko/.emacs.d/cache/" t))
      auto-save-list-file-prefix
      "/home/juiko/.emacs.d/cache/")


(setq-default tab-width 2)
(setq-default tramp-default-method "ssh")
(setq-default indent-tabs-mode nil)

(juiko/look-config)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e" "c74e83f8aa4c78a121b52146eadb792c9facc5b1f02c917e3dbb454fca931223" "3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" default)))
 '(package-selected-packages
   (quote
    (smart-mode-line pyenv-mode spacemacs-theme counsel-etags abyss-theme afternoon-theme ahungry-theme airline-themes alect-themes ample-theme ample-zen-theme anti-zenburn-theme apropospriate-theme arjen-grey-theme atom-dark-theme atom-one-dark-theme autothemer autumn-light-theme avk-emacs-themes badger-theme badwolf-theme base16-theme basic-theme birds-of-paradise-plus-theme blackboard-theme bliss-theme borland-blue-theme boron-theme bubbleberry-theme busybee-theme yaml-mode web-mode tide slime-company rtags robe req-package rbenv racer projectile-rails php-mode php-eldoc minitest material-theme leuven-theme js2-mode irony-eldoc intero iedit hlint-refactor hindent helm-swoop helm-projectile helm-gtags helm-ag go-eldoc flycheck-rust flycheck-pos-tip flycheck-irony flycheck-haskell flycheck-elm evil-smartparens evil-magit evil-lisp-state evil-leader evil-god-state evil-commentary elpy elm-mode dumb-jump company-quickhelp company-irony company-go company-ghci company-anaconda color-theme-approximate cider))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(flycheck-error ((t (:underline "Red1"))))
 '(flycheck-info ((t (:underline "ForestGreen"))))
 '(flycheck-warning ((t (:underline "DarkOrange")))))
