from cpython.pycapsule cimport PyCapsule_New, PyCapsule_Destructor, PyCapsule_GetPointer
from archive cimport ArchiveBackend

cdef extern from 'Archive.h':
    ctypedef struct Archive

cdef extern from 'git2/repository.h':
    ctypedef struct git_repository
    int git_repository_open(git_repository** repo_out, const char* path)
    void git_repository_free(git_repository* repo)

cdef extern from 'gitbackend.h':
    int init_repo(git_repository* repo, Archive* archive)


# Destructor for cleaning up Point objects
cdef del_Backend(object obj):
    pt = <git_repository *> PyCapsule_GetPointer(obj,"backend")
    git_repository_free(pt)


cdef class Backend:
    def __init__(self, ArchiveBackend archive, str path):
        self.backend = self.build_backend(archive=archive, str_path=path)

    def build_backend(self, ArchiveBackend archive, str str_path):
        py_byte_string = str_path.encode('UTF-8')
        cdef const char* path = py_byte_string
        cdef git_repository *repository = NULL;

        cdef int err = git_repository_open(&repository, path)

        if err < 0:
            git_repository_free(repository)
            raise Exception("could not open the repo error {}".format(err))

        err = init_repo(repository, &archive.archive)

        if err < 0:
            git_repository_free(repository)
            raise Exception("could not open the repo error {}".format(err))

        return PyCapsule_New(
            <void*> repository, "backend", <PyCapsule_Destructor>del_Backend)
