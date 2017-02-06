#include <Python.h>
#include <git2.h>
#include <git2/odb_backend.h>
#include <git2/refdb.h>
#include <git2/sys/refdb_backend.h>
#include <git2/sys/repository.h>
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free

from pygit2 import Repository as PyGit2Repo

# https://github.com/jmorse/pygit2/commit/6edb77f5
# https://github.com/jmorse/pygit2-backends/blob/master/pygit2_backends/
# repository.py
# https://github.com/jmorse/pygit2-backends/blob/master/src/pygit2_backends.c


cdef extern from 'Errors.h':
    ctypedef enum Errors:
        E_SUCCESS                       = 0
        E_SYSTEM_ERROR_ERRNO            = -1
        E_INDEX_MAX_SIZE_EXCEEDED       = -2
        E_INDEX_OUT_OF_BOUNDS           = -3
        E_FILE_READ_ERROR               = -4
        E_NOT_FOUND                     = -5
        E_UNKNOWN_ARCHIVE_VERSION       = -6
        E_INVALID_ARCHIVE_HEADER        = -7


cdef extern from 'ArchiveSaveResult.h':
    ctypedef struct ArchiveSaveResult:
        pass


cdef extern from 'Archive.h':
    ctypedef struct Archive:
        pass
    cdef void Archive_init(Archive* archive,
                      const char* base_file_path)

    cdef void Archive_free(Archive* archive)

    cdef bint Archive_has(const Archive* archive,
                          const char* key)

    cdef Errors Archive_add_empty_page(Archive* archive)

    cdef Errors Archive_add_page_by_name(Archive* archive,
                                         const char* filename);

    cdef Errors Archive_save(const Archive*           self,
                            ArchiveSaveResult*       result);


cdef extern from "git2.h":
    pass

cdef extern from "git2/oid.h":
    ctypedef struct git_oid:
        pass



cdef extern from 'git2/odb.h':
    ctypedef struct git_odb:
        pass

cdef extern from "git2/types.h":
    ctypedef enum git_otype:
        GIT_OBJ_ANY = -2		#/**< Object can be any of the following */
        GIT_OBJ_BAD = -1		#/**< Object is invalid. */
        GIT_OBJ__EXT1 = 0		#/**< Reserved for future use. */
        GIT_OBJ_COMMIT = 1		#/**< A commit object. */
        GIT_OBJ_TREE = 2		#/**< A tree (directory listing) object. */
        GIT_OBJ_BLOB = 3		#/**< A file revision object. */
        GIT_OBJ_TAG = 4		    #/**< An annotated tag object. */
        GIT_OBJ__EXT2 = 5		#/**< Reserved for future use. */
        GIT_OBJ_OFS_DELTA = 6   #/**< A delta, base is given by an offset. */
        GIT_OBJ_REF_DELTA = 7   # 3/**< A delta, base is given by object id. */


cdef extern from "git2/odb_backend.h":
    ctypedef struct git_odb_stream:
        pass

    ctypedef struct git_odb_backend:
        unsigned int version
        git_odb *odb
        int (* read)(void **, size_t *, git_otype *, git_odb_backend *, const git_oid *)

        # To find a unique object given a prefix of its oid.  The oid given
        # must be so that the remaining (GIT_OID_HEXSZ - len)*4 bits are 0s.

        int (* read_prefix)(
            git_oid *, void **, size_t *, git_otype *,
            git_odb_backend *, const git_oid *, size_t)

        int (* read_header)(
            size_t *, git_otype *, git_odb_backend *, const git_oid *);

         # Write an object into the backend. The id of the object has
         # already been calculated and is passed in.

        int (* write)(
            git_odb_backend *, const git_oid *, const void *, size_t, git_otype);

        int (* writestream)(
            git_odb_stream **, git_odb_backend *, git_off_t, git_otype);

        int (* readstream)(
            git_odb_stream **, git_odb_backend *, const git_oid *);

        int (* exists)(
            git_odb_backend *, const git_oid *);

        int (* exists_prefix)(
            git_oid *, git_odb_backend *, const git_oid *, size_t);

        int (* refresh)(git_odb_backend *);

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


supported_repo_attrs = [
    'TreeBuilder',
    'config',
    'create_blob',
    'create_blob_fromdisk',
    'create_blob_fromworkdir',
    'create_branch',
    'create_commit',
    'create_reference',
    'create_reference_direct',
    'create_reference_symbolic',
    'create_tag',
    'get',
    'git_object_lookup_prefix',
    'is_empty',
    'listall_branches',
    'listall_references',
    'lookup_branch',
    'lookup_reference',
    'merge_base',
    'read',
    'revparse_single',
    'walk',
    'write',
    'create_remote',
    'match_reference_glob'
]




class CustomBackend:


    def __init__(self):
        #self._c_struct = git_odb_backend(
        #    read = self.read
        #)
        pass

cdef class ArchiveBackend:
    cdef Archive* archive

    def __cinit__(self):
        self.archive = <Archive*> PyMem_Malloc(sizeof(Archive))
        if not self.archive:
            raise MemoryError()

    def __dealloc__(self):
        PyMem_Free(self.archive)

    def __init__(self, str root_file_path, list pages):
        Archive_init(archive=self.archive, base_file_path=root_file_path)
        for page in pages:
            self._add_page(page)

    cpdef void _add_page(self, str filename):
        error = Archive_add_page_by_name(archive=self.archive, filename=filename)
        if error == Errors.E_SUCCESS:
            return







class MysqlRepository(PyGit2Repo):
    # XXX XXX XXX dev signature, think some actual thoughts before publishing
    # this API
    def __init__(self):
        # Create a struct git_repository hooked up to a mysql backend
        backend =  CustomBackend()

        repo = self.backend._c_struct

        # Initialize parent class with given git repo. XXX, exceptions
        super(PyGit2Repo, self).__init__(None, repository_ptr=repo)
        self.backend = backend

    def __getattribute__(self, str attr):
        # Remove a ton of Repository object attributes that are out of scope
        # when operating on a custom backend (i.e. the index, working copy,
        # etc). It should be immediately apparent to the developer that these
        # are not supported.

        # First, potentially return an attribute error,
        foo = super(PyGit2Repo, self).__getattribute__(attr)

        # Now filter for things we support
        if attr.startswith('_'):
            return foo
        if attr in supported_repo_attrs:
            return foo

        raise Exception("Attribute \"{0}\" not supported by custom git backends"
                .format(attr))