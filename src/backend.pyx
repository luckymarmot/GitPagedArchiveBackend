#include <Python.h>
#include <git2.h>
#include <git2/odb_backend.h>
#include <git2/refdb.h>
#include <git2/sys/refdb_backend.h>
#include <git2/sys/repository.h>

cdef extern from "git2.h":
    pass

cdef extern from "git2/odb_backend.h":
    ctypedef struct git_odb_backend:
        pass

cdef extern from "git2/refdb.h":
    pass

cdef extern from "git2/sys/refdb_backend.h":
    pass

cdef extern from "git2/sys/repository.h":
    pass


"""
Declare other symbols that are going to be linked into this module. In an
ideal world the backends repo would export these via a header, that can be
worked towards
"""
