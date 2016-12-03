;;; latex-typeset.el -- LaTeX typeset utilities

;;     Copyright (C) 2016 MIYAZAKI Ryoichi

;;     This program is free software: you can redistribute it and/or modify
;;     it under the terms of the GNU General Public License as published by
;;     the Free Software Foundation, either version 3 of the License, or
;;     (at your option) any later version.

;;     This program is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;     GNU General Public License for more details.

;;     You should have received a copy of the GNU General Public License
;;     along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides three functions, `latex-typeset-and-preview',
;; `latex-typeset-and-preview-region', and `latex-preview-pdf'. 
;; They are available in any major-mode for LaTeX.

;; This package assumes the process of making pdf as follows :
;; .tex -> .dvi -> .pdf

;;; Setting Example

;; (add-hook 'yatex-mode-hook
;;           (lambda ()
;;             (require 'latex-typeset)
;;             (setf *latex-program* "uplatex"               ;; default is "platex"
;;                   *latex-pdf-program* "open"              ;; default is "evince"
;;                   *latex-rm-ext* '(".dvi" ".log" ".aux")) ;; default is '(".dvi")
;;             (local-set-key (kbd "C-c C-c") 'latex-typeset-and-preview)
;;             (local-set-key (kbd "C-c C-r") 'latex-typeset-and-preview-region)
;;             (local-set-key (kbd "C-c C-p") 'latex-preview-pdf)))

;;; Code

(defvar *latex-program* "platex")
(defvar *latex-pdf-program* "evince")
(defvar *latex-make-pdf-program* "dvipdfmx")
(defvar *latex-rm-ext* '(".dvi"))

(defvar *latex-src* nil)
(make-variable-buffer-local '*latex-src**)
(defvar *latex-buf* "*LaTeX TypeSetting*")

(defun latex-make-filename (ext)
  (concat (file-name-sans-extension *latex-src*) ext))

(defun latex-typeset-and-preview ()
  (interactive)
  (setf *latex-src* (buffer-file-name (current-buffer)))
  (when (buffer-modified-p (current-buffer)) (basic-save-buffer))
  (latex-typeset-and-preview-main))

(defun latex-typeset-and-preview-main ()
  (let* ((curwin (selected-window))
         (comint-scroll-to-bottom-on-output t)
         (command (concat *latex-program* " " *latex-src*))
         proc)
    (pop-to-buffer (get-buffer-create *latex-buf*))
    (setf default-directory (file-name-directory *latex-src*))
    (comint-mode)
    (erase-buffer)
    (ignore-errors (delete-process proc))
    (setf proc (start-process-shell-command "latex-typeset"
                                            *latex-buf*
                                            command))
    (set-process-sentinel proc 'latex-typeset-sentinel)
    (select-window curwin)))

(defun latex-typeset-sentinel (proc state)
  (let ((ps (process-status proc))
        (psbuf (process-buffer proc)))
    (when (eq ps 'exit)
      (when (= 0 (process-exit-status proc))
        (latex-make-pdf-and-preview)))))

(defun latex-make-pdf-and-preview ()
  (let* ((dvi (latex-make-filename ".dvi"))
         (proc (start-process-shell-command
                "latex-make-pdf"
                nil
                (concat *latex-make-pdf-program* " " dvi))))
    (set-process-sentinel proc 'latex-make-pdf-sentinel)))

(defun latex-make-pdf-sentinel (proc state)
  (let ((ps (process-status proc))
        (pdf (latex-make-filename ".pdf")))
    (when (eq ps 'exit)
      (if (= 0 (process-exit-status proc))
          (progn
            (start-process-shell-command
             "latex-rm-files"
             nil
             (mapconcat 'identity
                        (cons "rm" (mapcar 'latex-make-filename *latex-rm-ext*))
                        " "))
            (start-process-shell-command
             "latex-preview"
             nil
             (concat *latex-pdf-program* " " pdf)))
        (message "could not make %s" pdf)))))

(defun latex-preview-pdf ()
  (interactive)
  (let* ((pdf (concat (file-name-nondirectory
                       (file-name-sans-extension
                        (buffer-file-name))) ".pdf"))
         (cmd (read-shell-command "Preview PDF: "
                                  (concat *latex-pdf-program* " " pdf))))
    (cd default-directory)
    (if (file-exists-p pdf)
        (start-process-shell-command "latex-preview" nil cmd)
      (message "%s does not exist." pdf))))

(defun latex-typeset-and-preview-region (beg end)
  (interactive "r")
  (let* ((tmpfile (concat default-directory "LaTeX-TMP.tex"))
         (contents (buffer-substring beg end))
         header buf)
    (save-excursion
      (goto-char (point-min))
      (re-search-forward "\\\\begin{document}")
      (setf header (buffer-substring (point-min) (1+ (match-end 0)))))
    (setf buf (set-buffer (find-file-noselect tmpfile)))
    (erase-buffer)
    (mapc 'insert (list header contents "\\end{document}"))
    (basic-save-buffer)
    (setf *latex-src* tmpfile)
    (latex-typeset-and-preview-main)
    (kill-buffer buf)))

(provide 'latex-typeset)

;; Local Variables:
;; mode: emacs-lisp
;; End:
