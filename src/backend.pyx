#include <Python.h>
#include <git2.h>
#include <git2/odb_backend.h>
#include <git2/refdb.h>
#include <git2/sys/refdb_backend.h>
#include <git2/sys/repository.h>

from pygit2 import Repository as PyGit2Repo

# https://github.com/jmorse/pygit2/commit/6edb77f5
# https://github.com/jmorse/pygit2-backends/blob/master/pygit2_backends/
# repository.py
# https://github.com/jmorse/pygit2-backends/blob/master/src/pygit2_backends.c

cdef extern from "git2.h":
    pass

cdef extern from 'git2/odb.h':
    ctypedef struct git_odb:
        pass

cdef extern from "git2/odb_backend.h":
    ctypedef struct git_odb_backend:
        unsigned int version
        git_odb *odb
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
        self._c_struct = None
        pass


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