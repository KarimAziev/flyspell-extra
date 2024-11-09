;;; flyspell-extra.el --- Additional flyspell commands -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Karim Aziiev <karim.aziiev@gmail.com>

;; Author: Karim Aziiev <karim.aziiev@gmail.com>
;; URL: https://github.com/KarimAziev/flyspell-extra
;; Version: 0.1.0
;; Keywords: i18n
;; Package-Requires: ((emacs "28.1") (transient "0.6.0"))
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides additional commands and utilities for enhancing the
;; functionality of Flyspell, a spell-checking extension for Emacs.

;; Main commands:
;; - `flyspell-extra-menu': Display a transient menu for Flyspell commands.
;; - `flyspell-extra-buffer-or-region': Check spelling in the active region or entire buffer.
;; - `flyspell-extra-toogle-prog-mode': Toggle Flyspell programming mode.
;; - `flyspell-extra-add-word-at-point-to-dict': Add the word at point to the dictionary.

;;; Code:

(require 'transient)
(require 'flyspell)

(defun flyspell-extra-ispell-add-word-to-dict (word &optional file)
  "Add WORD to the personal dictionary FILE if not already present.

Argument WORD is the word to be added to the dictionary.

Optional argument FILE is the dictionary file to which the WORD will be added."
  (require 'ispell)
  (unless file (setq file ispell-personal-dictionary))
  (if-let* ((rep (with-temp-buffer
                  (insert-file-contents file)
                  (goto-char (point-max))
                  (unless (re-search-backward
                           (regexp-opt (list word) 'symbols) nil t 1)
                    (skip-chars-backward "\s\t\n")
                    (insert "\n" word)
                    (buffer-string)))))
      (progn (write-region rep nil ispell-personal-dictionary nil 0)
             (message "%s saved in %s" word file))
    (message "%s already in dictionary %s" word file)))

;;;###autoload
(defun flyspell-extra-buffer-or-region ()
  "Check spelling in the active region or the entire buffer."
  (interactive)
  (when (bound-and-true-p flyspell-mode)
    (if (and
         (region-active-p)
         (use-region-p))
        (flyspell-region (region-beginning)
                         (region-end))
      (flyspell-buffer))))

;;;###autoload
(defun flyspell-extra-toogle-prog-mode ()
  "Toggle `flyspell-prog-mode' based on its current state."
  (interactive)
  (if (bound-and-true-p flyspell-mode)
      (if (fboundp 'flyspell--mode-off)
          (flyspell--mode-off)
        (with-no-warnings (flyspell-mode-off)))
    (flyspell-prog-mode)))

(defun flyspell-extra-add-word-at-point-to-dict ()
  "Add the word at point to the dictionary and refresh Flyspell mode."
  (interactive)
  (let ((word
         (if-let* ((overlay
                   (seq-find #'flyspell-overlay-p (overlays-at
                                                   (point)))))
             (buffer-substring-no-properties (overlay-start overlay)
                                             (overlay-end overlay))
           (symbol-at-point))))
    (flyspell-extra-ispell-add-word-to-dict
     (read-string "Add to dictionary: " word))
    (when (bound-and-true-p flyspell-mode)
      (progn (flyspell-mode -1)
             (flyspell-mode 1)))))

(defun flyspell-extra-prev-error ()
  "Move to the previous spelling error."
  (interactive)
  (flyspell-goto-next-error t))

;;;###autoload (autoload 'flyspell-extra-menu "flyspell-extra" nil t)
(transient-define-prefix flyspell-extra-menu ()
  "Command dispatcher for flyspell."
  [("n" "Go to the next error"
    flyspell-goto-next-error :transient t)
   ("p"
    "Correct the closest previous word that is highlighted as misspelled"
    flyspell-extra-prev-error :transient t)
   ("."
    "Correct word before point using ‘flyspell-correct-interface’"
    flyspell-correct-at-point)
   ("w" "Word" flyspell-word :transient nil)
   ("C"
    "Pop up a menu of possible corrections for misspelled word before point"
    flyspell-correct-word-before-point :transient t)
   ("B" "Flyspell whole buffer."
    flyspell-buffer :transient t)]
  [("t"
    flyspell-mode
    :description (lambda ()
                   (concat "Toggle Spell checking "
                           (if
                               (bound-and-true-p
                                flyspell-mode)
                               (propertize "(on) "
                                           'face
                                           'success)
                             (propertize "(off) " 'face
                                         'error))))
    :transient t)
   ("P" flyspell-extra-toogle-prog-mode
    :description (lambda ()
                   (concat "Check strings and comments "
                           (if
                               (and (bound-and-true-p
                                     flyspell-mode)
                                    (eq flyspell-generic-check-word-predicate
                                        'flyspell-generic-progmode-verify))
                               (propertize "(on) "
                                           'face
                                           'success)
                             (propertize "(off) " 'face
                                         'error))))
    :transient t)])

(provide 'flyspell-extra)
;;; flyspell-extra.el ends here
