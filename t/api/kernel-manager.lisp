#|
  This file is a part of cl-cuda project.
  Copyright (c) 2012 Masayuki Takagi (kamonama@gmail.com)
|#

(in-package :cl-user)
(defpackage cl-cuda-test.api.kernel-manager
  (:use :cl :cl-test-more
        :cl-cuda.api.context
        :cl-cuda.api.kernel-manager)
  (:import-from :cl-cuda.api.kernel-manager
                :foo :bar))
(in-package :cl-cuda-test.api.kernel-manager)

(plan nil)


;;;
;;; test KERNEL-MANAGER's state transfer
;;;

(diag "KERNEL-MANAGER")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    (is (kernel-manager-compiled-p mgr) nil
        "basic case 1")
    (is (kernel-manager-module-handle mgr) nil
        "basic case 2")
    (is (kernel-manager-function-handles-empty-p mgr) t
        "basic case 3")
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 4")
    (is (kernel-manager-module-handle mgr) nil
        "basic case 5")
    (is (kernel-manager-function-handles-empty-p mgr) t
        "basic case 6")
    ;; III - module-loaded state
    (kernel-manager-load-module mgr)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 7")
    (is (not (null (kernel-manager-module-handle mgr))) t
        "basic case 8")
    (is (kernel-manager-function-handles-empty-p mgr) t
        "basic case 9")
    ;; IV - funciton-loaded state
    (kernel-manager-load-function mgr 'foo)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 10")
    (is (not (null (kernel-manager-module-handle mgr))) t
        "basic case 11")
    (is (kernel-manager-function-handles-empty-p mgr) nil
        "basic case 12")
    ;; II - compiled state
    (kernel-manager-unload mgr)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 13")
    (is (kernel-manager-module-handle mgr) nil
        "basic case 14")
    (is (kernel-manager-function-handles-empty-p mgr) t
        "basic case 15")
    ;; I - initial state
    (kernel-manager-define-function mgr 'foo 'void '() '())
    (is (kernel-manager-compiled-p mgr) nil
        "basic case 16")
    (is (kernel-manager-module-handle mgr) nil
        "basic case 17")
    (is (kernel-manager-function-handles-empty-p mgr) t
        "basic case 18")))


;;;
;;; test KERNEL-MANAGER-COMPILE-MODULE function
;;;

(diag "KERNEL-MANAGER-COMPILE-MODULE")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    nil
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    (is-error (kernel-manager-compile-module mgr) simple-error
              "KERNEL-MANAGER whose state is compiled state.")
    ;; III - module-loaded state
    (kernel-manager-load-module mgr)
    (is-error (kernel-manager-compile-module mgr) simple-error
              "KERNEL-MANAGER whose state is module-loaded state.")
    ;; IV - funciton-loaded state
    (kernel-manager-load-function mgr 'foo)
    (is-error (kernel-manager-compile-module mgr) simple-error
              "KERNEL-MANAGER whose state is function-loaded state.")))


;;;
;;; test KERNEL-MANAGER-LOAD-MODULE function
;;;

(diag "KERNEL-MANAGER-LOAD-MODULE")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    (is-error (kernel-manager-load-module mgr) simple-error
              "KERNEL-MANAGER whose state is initial state.")
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    nil
    ;; III - module-loaded state
    (kernel-manager-load-module mgr)
    (is-error (kernel-manager-load-module mgr) simple-error
              "KERNEL-MANAGER whose state is module-loaded state.")
    ;; IV - funciton-loaded state
    (kernel-manager-load-function mgr 'foo)
    (is-error (kernel-manager-load-module mgr) simple-error
              "KERNEL-MANAGER whose state is function-loaded state.")))


;;;
;;; test KERNEL-MANAGER-LOAD-FUNCTION function
;;;

(diag "KERNEL-MANAGER-LOAD-FUNCTION")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    (is-error (kernel-manager-load-function mgr 'foo) simple-error
              "KERNEL-MANAGER whose state is initial state.")
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    (is-error (kernel-manager-load-function mgr 'foo) simple-error
              "KERNEL-MANAGER whose state is compiled state.")
    ;; III - module-loaded state
    (kernel-manager-load-module mgr)
    nil
    ;; IV - function-loaded state
    (kernel-manager-load-function mgr 'foo)
    (is-error (kernel-manager-load-function mgr 'foo) simple-error
              "The kernel function FOO has been already loaded.")
    (is-error (kernel-manager-load-function mgr 'bar) simple-error
              "The kernel function BAR is not defined.")))

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; transfer state from I to II
    (kernel-manager-compile-module mgr)
    ;; delete kernel module
    (let ((module-path
           (cl-cuda.api.kernel-manager::kernel-manager-module-path mgr)))
      (delete-file module-path))
    ;; try to load module which does not exist
    (is-error (kernel-manager-load-module mgr) simple-error
           "The kernel module which KERNEL-MANAGER specifies does not exist.")))


;;;
;;; test KERNEL-MANAGER-UNLOAD function
;;;

(diag "KERNEL-MANAGER-UNLOAD")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    (ok (kernel-manager-unload mgr)
        "basic case 1")
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    (ok (kernel-manager-unload mgr)
        "basic case 2")
    ;; III - module-loaded state
    nil
    ;; IV - function-loaded state
    nil))


;;;
;;; test KERNEL-MANAGER-DEFINE-FUNCTION function
;;;

(diag "KERNEL-MANAGER-DEFINE-FUNCTION")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; transfer state from I to II
    (kernel-manager-define-function mgr 'foo 'void '() '())
    (kernel-manager-compile-module mgr)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 1")
    ;; defining function without change makes no state transfer
    (kernel-manager-define-function mgr 'foo 'void '() '())
    (is (kernel-manager-compiled-p mgr) t
        "basic case 2")
    ;; defining function with change makes state transfer
    (kernel-manager-define-function mgr 'foo 'int '((i int)) '(return i))
    (is (kernel-manager-compiled-p mgr) nil
        "basic case 3")))

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    (kernel-manager-define-function mgr 'foo 'void '() '())
    nil
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    nil
    ;; III - module-loaded state
    (kernel-manager-load-module mgr)
    (is-error (kernel-manager-define-function mgr 'bar 'void '() '())
              simple-error
              "KERNEL-MANAGER whose state is module-loaded state.")
    ;; IV - function-loaded state
    (kernel-manager-load-function mgr 'foo)
    (is-error (kernel-manager-define-function mgr 'bar 'void '() '())
              simple-error
              "KERNEL-MANAGER whose state is function-loaded state.")))


;;;
;;; test KERNEL-MANAGER-DEFINE-MACRO function
;;;

(diag "KERNEL-MANAGER-DEFINE-MACRO")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; transfer state from I to II
    (kernel-manager-define-macro mgr 'foo '() '() #'(lambda ()))
    (kernel-manager-compile-module mgr)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 1")
    ;; defining macro without change makes no state transfer
    (kernel-manager-define-macro mgr 'foo '() '() #'(lambda ()))
    (is (kernel-manager-compiled-p mgr) t
        "basic case 2")
    ;; defining macro with change makes state transfer
    (kernel-manager-define-macro mgr 'foo '(a) '(a) #'(lambda (a) a))
    (is (kernel-manager-compiled-p mgr) nil
        "basic case 3")))

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    (kernel-manager-define-function mgr 'foo 'void '() '())
    nil
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    nil
    ;; III - module-loaded state
    (kernel-manager-load-module mgr)
    (is-error (kernel-manager-define-macro mgr 'bar '() '() #'(lambda ()))
              simple-error
              "KERNEL-MANAGER whose state is module-loaded state.")
    ;; IV - function-loaded state
    (kernel-manager-load-function mgr 'foo)
    (is-error (kernel-manager-define-macro mgr 'bar '() '() #'(lambda ()))
              simple-error
              "KERNEL-MANAGER whose state is function-loaded state.")))


;;;
;;; test KERNEL-MANAGER-DEFINE-SYMBOL-MACRO function
;;;

(diag "KERNEL-MANAGER-DEFINE-SYMBOL-MACRO")

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; transfer state from I to II
    (kernel-manager-define-symbol-macro mgr 'foo 1)
    (kernel-manager-compile-module mgr)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 1")
    ;; defining macro without change makes no state transfer
    (kernel-manager-define-symbol-macro mgr 'foo 1)
    (is (kernel-manager-compiled-p mgr) t
        "basic case 2")
    ;; defining macro with change makes state transfer
    (kernel-manager-define-symbol-macro mgr 'foo 2)
    (is (kernel-manager-compiled-p mgr) nil
        "basic case 3")))

(let* ((mgr (make-kernel-manager))
       (*kernel-manager* mgr))
  (with-cuda-context (0)
    ;; I - initial state
    (kernel-manager-define-function mgr 'foo 'void '() '())
    nil
    ;; II - compiled state
    (kernel-manager-compile-module mgr)
    nil
    ;; III - module-loaded state
    (kernel-manager-load-module mgr)
    (is-error (kernel-manager-define-symbol-macro mgr 'foo 1) simple-error
              "KERNEL-MANAGER whose state is module-loaded state.")
    ;; IV - function-loaded state
    (kernel-manager-load-function mgr 'foo)
    (is-error (kernel-manager-define-symbol-macro mgr 'foo 2) simple-error
              "KERNEL-MANAGER whose state is function-loaded state.")))


(finalize)
