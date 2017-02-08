
cdef extern from 'Archive.h':
    ctypedef struct Archive:
        pass

cdef class ArchiveBackend:
    cdef Archive archive

    cpdef bytes get(self, str key)