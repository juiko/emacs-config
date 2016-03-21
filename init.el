;; -*- lexical-binding: t -*-

(setf lexical-binding t)

(setq gc-cons-threshold 100000000)

(eval-when-compile
  (require 'cl))
(require 'package)

(progn
  (add-to-list 'package-archives
	       '("melpa" . "http://melpa.org/packages/") t)
  (package-initialize)

  (when (not (package-installed-p 'req-package))
    (package-refresh-contents)
    (package-install 'req-package)))

(defun python-find-env (project-root)
  (let ((env-path (f-join project-root "env")))
    (when (f-exists? env-path)
      env-path)))

(let (python-current-env)
  (add-hook 'python-mode-hook
	    (lambda ()
	      (let* ((root (projectile-project-root))
		     (env (python-find-env root)))
		(when (and env
			   (not (equal env
				       python-current-env)))
		  (setf python-current-env env)
		  (message "Current python env: %s" python-current-env)
		  (pyvenv-activate env))))))

(defun async-gtags-update ()
  (call-process "global" nil 0 nil "-u"))

(defvar *gtags-modes*
  '(web-mode
    php-mode
    cperl-mode))

(add-hook 'after-save-hook
	  (lambda ()
	    (if (cl-member major-mode *gtags-modes*)
		(async-gtags-update))))

(defun endless/upgrade ()
  "Upgrade all packages, no questions asked."
  (interactive)
  (save-window-excursion
    (list-packages)
    (package-menu-mark-upgrades)
    (package-menu-execute 'no-query)))

(eldoc-mode t)
(setq inhibit-startup-message t)
(fset 'yes-or-no-p 'y-or-n-p)

(setq backup-by-copying t      ; don't clobber symlinks
      backup-directory-alist
      '(("." . "~/.emacs.d/saves"))    ; don't litter my fs tree
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)



(add-hook 'after-save-hook
	  (lambda ()
	    (let ((init-file (expand-file-name "~/.emacs.d/init.el")))
	      (when (equal (buffer-file-name) init-file)
		(byte-compile-file init-file)))))

(add-hook 'after-save-hook
	  'whitespace-cleanup)

(setq browse-url-browser-function 'browse-url-firefox)

(progn
  (defalias 'perl-mode 'cperl-mode)
  (setq cperl-electric-parens nil
	cperl-electric-keywords nil
	cperl-electric-lbrace-space nil))

(setq backup-directory-alist
      '((".*" . "/home/juiko/.emacs.d/cache/"))
      auto-save-file-name-transforms
      '((".*" "/home/juiko/.emacs.d/cache/" t))
      auto-save-list-file-prefix
      "/home/juiko/.emacs.d/cache/")

(require 'req-package)

(req-package f)

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
	    (setq company-minimum-prefix-length 3)
	    (setq company-show-numbers t)
	    (global-company-mode)))

(req-package company-quickhelp
  :require company
  :config (add-hook 'company-mode-hook 'company-quickhelp-mode))

(req-package flycheck
  :config (progn
	    (setf flycheck-perlcritic-severity 5)
	    (setf flycheck-ghc-args (list
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
	    (global-flycheck-mode)))

(req-package flycheck-pos-tip
  :require flycheck
  :config (progn
	    (setf flycheck-display-errors-function
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
			  (smartparens-strict-mode))))))

(req-package slime-company
  :require company)

(req-package slime
  :require slime-company
  :commands (slime)
  :init (progn
	  (setq inferior-lisp-program "sbcl")
	  (setq slime-contrib '(slime-fancy
				slime-company))
	  (setq slime-sbcl-manual-root "/usr/local/share/info/sbcl.info")
	  (add-hook 'lisp-mode-hook
		    (lambda ()
		      (unless (slime-connected-p)
			(save-excursion (slime))))))
  :config (progn
	    (slime-setup '(slime-fancy slime-company))))

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

	    (setq evil-move-cursor-back nil)

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
				   inferior-python-mode)
		     do (evil-set-initial-state mode 'emacs))


	    (evil-mode)))


(req-package evil-lisp-state
  :require evil evil-leader bind-key
  :init (progn
	  (setq evil-lisp-state-global t)
	  (setq evil-lisp-state-enter-lisp-state-on-command nil))
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
	    (setq evil-leader/leader (kbd ","))
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

(defun juiko/look-config ()
  (blink-cursor-mode -1)
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (column-number-mode 1)
  (global-hl-line-mode 1)
  (show-paren-mode)
  (add-to-list 'default-frame-alist '(font . "Hack-9"))
  (add-to-list 'default-frame-alist '(cursor-color . "Gray")))

;; (progn
;;   (require 'spacemacs-light-theme)
;;   (load-theme 'spacemacs-light t)
;;   (juiko/look-config))

;; (req-package spacemacs-theme-pkg
;;   :ensure spacemacs-theme
;;   :config (progn
;;	    (load-theme 'spacemacs-ligt t)
;;	    (juiko/look-config)))

(req-package paper-theme
  :if window-system
  :config (progn
	    (load-theme 'paper t)
	    (juiko/look-config)))

(req-package badwolf-theme
  :disabled t
  :config (progn
	    (load-theme 'badwolf t)
	    (juiko/look-config)))

(req-package greymatters-theme
  :disabled t
  :config (progn
	    (add-hook 'after-init-hook
		      (lambda ()
			(load-theme 'greymatters t)
			(set-face-attribute 'fringe
					    nil
					    :background "#f9fbfd"
					    :foreground "#f9fbfd")))
	    (juiko/look-config)))

(req-package leuven-theme
  :disabled t
  :config (progn
	    (add-hook 'after-init-hook
		      (lambda ()
			(load-theme 'leuven t)
			(set-face-attribute 'fringe
					    nil
					    :background "2e3436"
					    :foreground "2e3436")
			(juiko/look-config)))))

(req-package railscasts-theme
  :disabled t
  :config (progn
	    (load-theme 'railscasts t)
	    (juiko/look-config)))

(req-package projectile
  :config (progn
	    (add-hook 'after-init-hook 'projectile-global-mode)))

(req-package helm-config
  :config (progn

	    (bind-key "M-x" 'helm-M-x)
	    (bind-key "C-x C-f" 'helm-find-files)

	    (setq helm-split-window-in-side-p t)

	    (add-to-list 'display-buffer-alist
			 '("\\`\\*helm.*\\*\\'"
			   (display-buffer-in-side-window)
			   (inhibit-same-window . t)
			   (window-height . 0.4)))

	    (setq helm-swoop-split-with-multiple-windows nil
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

(req-package magit
  :init (progn
	  (setq magit-last-seen-setup-instructions "1.4.0")))

(req-package haskell-mode
  :config (progn
	    (define-key haskell-mode-map (kbd "C-c C-l") 'haskell-process-load-file)
	    (add-hook 'haskell-mode-hook 'haskell-doc-mode)
	    (add-hook 'haskell-mode-hook 'haskell-indentation-mode)
	    (add-hook 'haskell-mode-hook 'interactive-haskell-mode)
	    (add-hook 'haskell-mode-hook 'haskell-decl-scan-mode)
	    (add-hook 'haskell-mode-hook (lambda ()
					   (electric-indent-local-mode -1)))
	    ;; (add-hook 'haskell-mode-hook 'electric-pair-local-mode)

	    ;; (add-hook 'haskell-mode-hook
	    ;;	      (lambda ()
	    ;;		(flycheck-disable-checker 'haskell-hlint)))

	    (setq haskell-process-type 'stack-ghci)
	    (setq haskell-process-path-ghci "stack")
	    (setq haskell-process-args-ghci '("ghci"))

	    (setq haskell-process-suggest-remove-import-lines t)
	    (setq haskell-process-auto-import-loaded-modules t)
	    (setq haskell-process-log nil)
	    (setq haskell-stylish-on-save t)))


(req-package hindent
  :require haskell-mode
  :config (progn
	    (setq hindent-style "chris-done")
	    (evil-define-key 'evil-visual-state hindent-mode-map "TAB"
	      'hindent-reformat-region)
	    (add-hook 'haskell-mode-hook 'hindent-mode)))

(req-package flycheck-haskell
  :require flycheck haskell-mode
  :config (progn
	    (add-hook 'haskell-mode-hook 'flycheck-mode)
	    (add-hook 'flycheck-mode-hook 'flycheck-haskell-configure)))

(req-package company-ghci
  :require company haskell-mode
  :config (progn
	    (add-hook 'haskell-mode-hook
		      (lambda ()
			(setq-local company-backends
				    '(company-ghci
				      company-dabbrev
				      company-dabbrev-code))))))


(req-package hlint-refactor
  :require haskell-mode
  :config (progn
	    (bind-key "C-c h r" 'hlint-refactor-refactor-at-point hlint-refactor-mode-map)

	    (add-hook 'haskell-mode-hook 'hlint-refactor-mode)))

(req-package anaconda-mode
  :config (progn
	    (add-hook 'python-mode-hook 'anaconda-mode)))

(req-package company-anaconda
  :require company anaconda-mode
  :config (progn
	    (add-hook 'anaconda-mode-hook
		      (lambda ()
			(make-variable-buffer-local 'company-backends)
			(setq-local company-backends '(company-anaconda))))
	    ))

(req-package pyvenv
  :config (progn
	    (add-hook 'python-mode-hook 'pyvenv-mode)))

(req-package yasnippet
  :disabled t
  :config (progn
	    (yas-global-mode)))

(req-package irony
  :config (progn
	    (add-hook 'c-mode-hook 'irony-mode)
	    (add-hook 'c++-mode-hook 'irony-mode)
	    (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)))

(req-package company-irony
  :require company irony
  :commands (irony-mode)
  :config (progn
	    (push 'company-irony company-backends)))

(req-package flycheck-irony
  :require flyckeck irony
  :config (add-hook 'flycheck-mode-hook 'flycheck-irony-setup))

(req-package irony-eldoc
  :require irony
  :config (progn
	    (add-hook 'irony-mode-hook 'eldoc-mode)))


(req-package web-mode
  :config (progn
	    (add-hook 'web-mode-hook
		      (lambda ()
			(setq web-mode-enable-auto-pairing t)
			(setq web-mode-enable-css-colorization t)
			(setq web-mode-enable-block-face t)
			(setq web-mode-enable-heredoc-fontification t)
			(setq web-mode-enable-current-element-highlight nil)
			(setq web-mode-enable-current-column-highlight nil)
			(setq web-mode-code-indent-offset 2)
			(setq web-mode-markup-indent-offset 2)
			(setq web-mode-css-indent-offset 2)))
	    (add-to-list 'auto-mode-alist '("\\.blade\\.php\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
	    (add-to-list 'auto-mode-alist '("\\.html\\'" . web-mode))))

(req-package php-mode
  :disabled t
  :config (progn
	    (require 'php-ext)
	    (setq php-template-compatibility nil)))

(req-package js2-mode
  :config (progn
	    (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))))

(req-package rust-mode
  )

(req-package racer
  :require rust-mode company
  :config (progn
	    (setq racer-cmd "/home/juiko/git/racer/target/release/racer")
	    (setq racer-rust-src-path "/home/juiko/git/rust/src/")
	    (add-hook 'rust-mode-hook 'racer-mode)
	    (add-hook 'racer-mode-hook 'eldoc-mode)
	    ))

(req-package flycheck-rust
  :require rust-mode flycheck
  :config (progn
	    (add-hook 'flycheck-mode-hook 'flycheck-rust-setup)))
(req-package elm-mode)

(req-package flycheck-elm
  :require elm-mode flycheck
  :config (progn
	    (add-hook 'flycheck-mode-hook 'flycheck-elm-setup)))

(req-package color-theme-approximate
  :config (progn
	    (color-theme-approximate-on)))

(req-package-finish)

(juiko/look-config)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (color-theme-approximate yasnippet web-mode tao-theme slime-company req-package railscasts-theme racer pyvenv php-mode paper-theme leuven-theme js2-mode irony-eldoc iedit hlint-refactor hindent helm-swoop helm-projectile helm-ag greymatters-theme flycheck-rust flycheck-pos-tip flycheck-irony flycheck-haskell flycheck-elm evil-smartparens evil-magit evil-lisp-state evil-leader evil-god-state evil-commentary elm-mode company-quickhelp company-irony company-ghci company-anaconda badwolf-theme))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
