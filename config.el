;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "+Howard Wang"
      user-mail-address "+howardwang99915@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!
;;
;; We first define the setup for general doom
(setq doom-font (font-spec :family "JetBrains Mono" :size 18)
      doom-variable-pitch-font (font-spec :family "Source Sans Pro" :size 18)
      doom-serif-font (font-spec :family "Source Serif Pro" :size 18)
      doom-big-font (font-spec :family "JetBrains Mono" :size 24))

;;;###autoload
(defun +howard/org-font-setup ()
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.35)
                  (org-level-2 . 1.25)
                  (org-level-3 . 1.2)
                  (org-level-4 . 1.15)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.0)
                  (org-level-7 . 1.0)
                  (org-level-8 . 1.0)))
    (set-face-attribute (car face) nil :font "Dejavu Sans Mono" :weight 'semi-bold :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-document-title nil :inherit 'variable-pitch :weight 'semi-bold :height 1.2)
  (set-face-attribute 'org-document-info-keyword nil :inherit 'variable-pitch)
  (set-face-attribute 'org-tag nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-block-begin-line nil :inherit '(shadow fixed-pitch)))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-palenight)

;; This determines the line numbers type. You can make emacs display relative numbers
;; if you like.
(setq display-line-numbers-type t)

;; Set a scroll margin to keep cursor in the middle of the screen.
(setq scroll-margin 12)
(setq maximum-scroll-margin 0.5)
; Better mouse scrolling
(setq mouse-wheel-progressive-speed nil)

;; This portion is for the org mode font setup
(defun howard/org-refile-to-datetree (&optional file)
  "Refile a subtree to a datetree corresponding to it's timestamp.

  The current time is used if the entry has no timestamp. If FILE
  is nil, refile in the current file."
  (interactive "f")
  (let* ((datetree-date (or (org-entry-get nil "TIMESTAMP" t)
                            (org-read-date t nil "now")))
         (date (org-date-to-gregorian datetree-date))
         )
    (with-current-buffer (current-buffer)
      (save-excursion
        (org-cut-subtree)
        (if file (find-file file))
        (org-datetree-find-date-create date)
        (org-narrow-to-subtree)
        (show-subtree)
        (org-end-of-subtree t)
        (newline)
        (goto-char (point-max))
        (org-paste-subtree 4)
        (widen)
        ))
    )
  )
;; This section, we place several agenda helper functions in here.
;;;###autoload
(defun +howard/org-agenda-project-warning ()
  "Is a project stuck or waiting. If the project is not stuck,
show nothing. However, if it is stuck and waiting on something,
show this warning instead."
  (if (+howard/org-agenda-project-is-stuck)
    (if (+howard/org-agenda-project-is-waiting) " !W" " !S") ""))

;;;###autoload
(defun +howard/org-agenda-project-is-stuck ()
  "Is a project stuck"
  (if (+howard/is-project-p) ; first, check that it's a project
      (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
         (has-next))
    (save-excursion
      (forward-line 1)
      (while (and (not has-next)
              (< (point) subtree-end)
              (re-search-forward "^\\*+ NEXT " subtree-end t))
        (unless (member "WAITING" (org-get-tags-at))
          (setq has-next t))))
    (if has-next nil t)) ; signify that this project is stuck
    nil)) ; if it's not a project, return an empty string

;;;###autoload
(defun +howard/org-agenda-project-is-waiting ()
  "Is a project stuck"
  (if (+howard/is-project-p) ; first, check that it's a project
      (let* ((subtree-end (save-excursion (org-end-of-subtree t))))
    (save-excursion
      (re-search-forward "^\\*+ WAITING" subtree-end t)))
    nil)) ; if it's not a project, return an empty string

;; Some helper functions for agenda views
;;;###autoload
(defun +howard/org-agenda-prefix-string ()
  "Format"
  (let ((path (org-format-outline-path (org-get-outline-path))) ; "breadcrumb" path
    (stuck (+howard/org-agenda-project-warning))) ; warning for stuck projects
       (if (> (length path) 0)
       (concat stuck ; add stuck warning
           " [" path "]") ; add "breadcrumb"
     stuck)))

;;;###autoload
(defun +howard/is-project-p ()
  "A task with a 'PROJ' keyword"
  (member (nth 2 (org-heading-components)) '("PROJ")))

;;;###autoload
(defun +howard/is-project-subtree-p ()
  "Any task with a todo keyword that is in a project subtree.
Callers of this function already widen the buffer view."
  (let ((task (save-excursion (org-back-to-heading 'invisible-ok)
                              (point))))
    (save-excursion
      (+howard/find-project-task)
      (if (equal (point) task)
          nil t))))

;;;###autoload
(defun +howard/find-project-task ()
  "Any task with a todo keyword that is in a project subtree"
  (save-restriction
    (widen)
    (let ((parent-task (save-excursion (org-back-to-heading 'invisible-ok) (point))))
      (while (org-up-heading-safe)
    (when (member (nth 2 (org-heading-components)) '("PROJ"))
      (setq parent-task (point))))
      (goto-char parent-task)
      parent-task)))

;;;###autoload
(defun +howard/select-with-tag-function (select-fun-p)
  (save-restriction
    (widen)
    (let ((next-headline
           (save-excursion (or (outline-next-heading)
                               (point-max)))))
      (if (funcall select-fun-p) nil next-headline))))

;;;###autoload
(defun +howard/select-projects ()
  "Selects tasks which are project headers"
  (+howard/select-with-tag-function #'howard/is-project-p))
(defun +howard/select-project-tasks ()
  "Skips tags which belong to projects (and is not a project itself)"
  (+howard/select-with-tag-function
   #'(lambda () (and
                 (not (+howard/is-project-p))
                 (+howard/is-project-subtree-p)))))

;;;###autoload
(defvar +howard-org-agenda-block--today-schedule
  '(agenda "" ((org-agenda-overriding-header "🗓 Today's Schedule:")
               (org-agenda-span 'day)
               (org-agenda-ndays 1)
               (org-deadline-warning-days 1)
               (org-agenda-start-on-weekday nil)
               (org-agenda-start-day "+0d")))
    "A block showing a 1 day schedule.")

;;;###autoload
(defvar +howard-org-agenda-block--weekly-log
  '(agenda "" ((org-agenda-overriding-header "📅 Weekly Log")
               (org-agenda-span 'week)
               (org-agenda-start-day "+1d")))
  "A block showing my schedule and logged tasks for this week.")

;;;###autoload
(defvar +howard-org-agenda-block--three-days-sneak-peek
  '(agenda "" ((org-agenda-overriding-header "3⃣ Next Three Days")
               (org-agenda-start-on-weekday nil)
               (org-agenda-start-day "+1d")
               (org-agenda-span 3)))
  "A block showing what to do for the next three days. ")

;;;###autoload
(defvar +howard-org-agenda-block--active-projects
    '(tags-todo "-INACTIVE-LATER-CANCELLED-REFILEr/!"
                ((org-agenda-overriding-header "📚 Active Projects:")
                 (org-agenda-skip-function 'howard/select-projects)))
    "All active projects: no inactive/someday/cancelled/refile.")

;;;###autoload
(defvar +howard-org-agenda-block--next-tasks
  '(tags-todo "-INACTIVE-LATER-CANCELLED-ARCHIVE/!NEXT"
              ((org-agenda-overriding-header "👉 Next Tasks:")))
  "Next tasks.")

;;;###autoload
(defvar +howard-org-agenda-display-settings
  '((org-agenda-start-with-log-mode t)
    (org-agenda-log-mode-items '(clock))
    (org-agenda-prefix-format '((agenda . "  %-12:c%?-12t %(howard/org-agenda-add-location-string)% s")
                                (timeline . "  % s")
                                (todo . "  %-12:c %(howard/org-agenda-prefix-string) ")
                                (tags . "  %-12:c %(howard/org-agenda-prefix-string) ")
                                (search . "  %i %-12:c"))))
  "Display settings for my agenda views.")

;;;###autoload
(defvar +howard-org-agenda-block--remaining-project-tasks
  '(tags-todo "-INACTIVE-SOMEDAY-CANCELLED-WAITING-REFILE-ARCHIVE/!-NEXT"
              ((org-agenda-overriding-header "Remaining Project Tasks:")
               (org-agenda-skip-function 'howard/select-project-tasks)))
  "Non-NEXT TODO items belonging to a project.")

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/Org-Files")
;; We put our org setup functions here
(after! org
  (add-hook! 'org-mode-hook #'mixed-pitch-mode)
  (add-hook! 'org-mode-hook #'solaire-mode)
  (add-hook! 'org-mode-hook
            #'(lambda () (display-line-numbers-mode 0)))
  (+howard/org-font-setup)
  (setq org-agenda-files
        '("~/Documents/Org-Files/Tasks/Tasks.org" "~/Documents/Org-Files/Tasks/Archive.org" "~/Documents/Org-Files/Tasks/Gcal.org"))
  (setq org-capture-templates
        '(("t" "Task" entry (file+headline "~/Documents/Org-Files/Tasks/Tasks.org" "Tasks")
           "* %^{Select your option|TODO|LATER|} %?\n SCHEDULED: %^T")
          ("p" "Project" entry (file+headline "~/Documents/Org-Files/Tasks/Tasks.org" "Projects")
           "* PROJ %?")))
  (setq org-agenda-custom-commands
        `(("d" "Daily Agenda"
           (,+howard-org-agenda-block--today-schedule
            ,+howard-org-agenda-block--three-days-sneak-peek
            ,+howard-org-agenda-block--active-projects
            ,+howard-org-agenda-block--next-tasks
            ,+howard-org-agenda-block--remaining-project-tasks))))
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "PROJ(p)" "|" "DONE(d!)")
          (sequence "WAITING(w@/!)" "INACTIVE(i)" "LATER(l)" "|" "CANCELED(c@/!)")))
  (setq org-hide-emphasis-markers t)
  (setq
   org-superstar-headline-bullets-list '("⁖" "◉" "○" "✸" "✿")))

(after! evil-escape
  (setq-default evil-escape-unordered-key-sequence t)
  (setq-default evil-escape-delay 0.1))

(after! pdf-tools
  (add-hook! pdf-outline-buffer-mode (display-line-numbers-mode -1)))

(after! eshell
  (add-hook 'eshell-mode-hook
    (lambda ()
      (make-local-variable 'scroll-margin)
      (setq scroll-margin 0))))

;; emms configuration
;; (after! emms
;;   (setq emms-info-functions '(emms-info-exiftool))
;;   (setq emms-player-list '(emms-player-mpv))
;;   (setq emms-seek-seconds 5)
;;   (setq emms-browser-covers 'emms-browser-cache-thumbnail-async))

;; org roam configuration
(after! org-roam
  (setq org-roam-dailies-directory "~/Documents/Org-Files/OrgRoam/journal")
  (setq org-roam-mode-sections
      (list #'org-roam-backlinks-section
            #'org-roam-reflinks-section
            ;; #'org-roam-unlinked-references-section
            ))
  (setq org-roam-directory "~/Documents/Org-Files/OrgRoam"))

;; Key binding for m-x
(map!
 :leader
 :desc "m-x" "SPC" #'execute-extended-command)
;; Handy keybindings
(map!
 :desc "next buffer" "C-S-L" #'evil-prev-buffer
 :desc "next buffer" "C-S-H" #'evil-next-buffer
 :desc "prev window" "C-S-K" #'evil-window-prev
 :desc "next window" "C-S-J" #'evil-window-next)
;; Dired keybindings
(map!
 :after dired
 :map dired-mode-map
 :desc "dired-find-file" :n "l" #'dired-find-file
 :desc "dired-create-empty-file" :n "a" #'dired-create-empty-file
 :desc "dired-up-directory" :n "h" #'dired-up-directory)
