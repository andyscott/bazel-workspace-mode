;;; bazel-workspace.el ---  Andy's Bazel Workspace Support

;; Author: Andy Scott <andy.g.scott@gmail.com>
;; URL: https://github.com/andyscott/<TODO>
;; Keywords: bazel

;; Package-Requires: ((emacs "26.0"))

;; Copyright (C) 2019, Andy Scott <andy.g.scott@gmail.com>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.
;;

;;; Commentary:

;;; Code:

(require 'compile)

(define-minor-mode bazel-workspace-mode
  "Bazel workspace mode"
  :lighter " BazelWS"
  :keymap (let ((map (make-sparse-keymap)))
	    (define-key map (kbd "C-c C-c b") 'bazel-workspace/bazel-at-point-b)
	    (define-key map (kbd "C-c C-c C-b") 'bazel-workspace/bazel-at-point-b)
	    (define-key map (kbd "C-c C-c f") 'bazel-workspace/bazel-at-point-f)
	    (define-key map (kbd "C-c C-c C-f") 'bazel-workspace/bazel-at-point-f)
	    (define-key map (kbd "C-c C-c t") 'bazel-workspace/bazel-at-point-t)
	    (define-key map (kbd "C-c C-c C-t") 'bazel-workspace/bazel-at-point-t)
	    map)
  :group 'bazel)

(when (package-installed-p 'hydra)
  (progn
    (defhydra bazel-workspace/menu-command (:color pink :hint nil)
      "bazel"
      ("q" bazel-workspace/command-query "query" :exit t)
      ("b" bazel-workspace/command-build "build" :exit t)
      ("t" bazel-workspace/command-test "test" :exit t))))


(defun bazel-workspace/command-query ()
  "Run a bazel query."
  (interactive)
  (message "run a query"))

(defun bazel-workspace/command-build ()
  "Run a bazel query."
  (interactive)
  (message "run a query"))

(defun bazel-workspace/command-test ()
  "Run a bazel query."
  (interactive)
  (message "run a query"))

(defun bazel-workspace/find-root (pathname)
  "Find the workspace root above PATHNAME."
  (let ((file (locate-dominating-file pathname "WORKSPACE")))
    (when file (file-name-directory file))))

(defun bazel-workspace/hooks/find-file ()
  "Find file hook for baz."
  (when (and buffer-file-name
             (bazel-workspace/find-root buffer-file-name))
    (bazel-workspace-mode +1)))

(add-hook 'find-file-hook #'bazel-workspace/hooks/find-file)

(define-compilation-mode bazel-target-compilation-mode "Bazel target compilation mode"
  "Major mode for interacting with Bazel targets.")

(when (require 'ansi-color nil t)
  (defun bazel-workspace/hooks/compilation-filter-hook ()
    (when (eq major-mode 'bazel-target-compilation-mode)
      (let ((inhibit-read-only t))
	(ansi-color-apply-on-region compilation-filter-start (point)))))
  (add-hook 'compilation-filter-hook 'bazel-workspace/hooks/compilation-filter-hook))

(defun bazel-target/compilation-start (args)
  "ARGS!!!"
  (interactive)
  (let ((command (string-join (cons "bazel" args) " ")))
    (compilation-start command 'bazel-target-compilation-mode)))

(defconst this-install-dir
  (if load-file-name
      (file-name-directory load-file-name)
    default-directory))

(defun bazel-workspace/bazel-at-point-b () "." (interactive) (bazel-workspace/bazel-at-point "b"))
(defun bazel-workspace/bazel-at-point-f () "." (interactive) (bazel-workspace/bazel-at-point "f"))
(defun bazel-workspace/bazel-at-point-t () "." (interactive) (bazel-workspace/bazel-at-point "t"))

(defun bazel-workspace/bazel-at-point (hint)
  "Attempt to run Bazel with HINT, intelligently, for whatever is at the current point."
  (interactive)
  (let* ((mode (pcase hint
		     ("b" "build")
		     ("f" "format")
		     ("t" "test")
		     (other (error "Unknown hint `%s'" other))))
	 (cmd (expand-file-name "./bazel-at-point.sh" this-install-dir))
	 (file (buffer-file-name))
	 (root (bazel-workspace/find-root file))
	 (rel (file-relative-name file root))
	 (pos (number-to-string (point)))
	 (target (with-temp-buffer
	        (call-process
		 cmd nil (current-buffer) nil
		 mode root rel pos)
		(buffer-string))))
    (if (not (string-match "^\s*$" target))
	(progn
	  (message (concat "target is: " target))
	  (bazel-target/compilation-start (list "build" target)))
      (progn
	(message "no target found :(")))))


(provide 'bazel-workspace)
;;; bazel-workspace.el ends here
