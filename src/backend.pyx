print("Hello")


# https://github.com/jmorse/pygit2/commit/6edb77f5
# https://github.com/jmorse/pygit2-backends/blob/master/pygit2_backends/
# repository.py
# https://github.com/jmorse/pygit2-backends/blob/master/src/pygit2_backends.c


cdef extern from "Python.h":
    ctypedef struct PyObject
    cdef PyObject *PyExc_IOError
    PyObject *PyErr_SetFromErrno(PyObject *)


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



class ArchiveLibIndexMaxSizeOverflowException(OverflowError):
    pass

class ArchiveLibIndexOutOfBoundsException(IndexError):
    pass

class ArchiveLibFileReadError(IOError):
    pass

class ArchiveLibItemNotFoundError(KeyError):
    pass


class ArchiveLibUnknownArchiveVersionError(IOError):
    pass

class ArchiveLibInvalidArchiveHeaderError(IOError):
    pass

def raise_on_error(Errors error):
    if error >= 0:
        return
    if error == E_SYSTEM_ERROR_ERRNO:
        PyErr_SetFromErrno(PyExc_IOError)
        return None

    if error == E_INDEX_MAX_SIZE_EXCEEDED:
        raise ArchiveLibIndexMaxSizeOverflowException()

    if error == E_INDEX_OUT_OF_BOUNDS:
        raise ArchiveLibIndexOutOfBoundsException()

    if error == E_FILE_READ_ERROR:
        raise ArchiveLibFileReadError()

    if error == E_NOT_FOUND:
        raise ArchiveLibItemNotFoundError()

    if error == E_UNKNOWN_ARCHIVE_VERSION:
        raise ArchiveLibUnknownArchiveVersionError()

    if error == E_INVALID_ARCHIVE_HEADER:
        raise ArchiveLibInvalidArchiveHeaderError()



cdef extern from 'ArchiveSaveResult.h':
    ctypedef struct ArchiveSaveFile:
        char* filename
        bint  has_changes

    ctypedef struct ArchiveSaveResult:
        ArchiveSaveFile* files
        size_t           count

    inline void ArchiveSaveResult_free(ArchiveSaveResult* result)


cdef class ArchiveFiles:
    cdef ArchiveSaveResult results

    def __init__(self):
        pass

    def to_list(self, changed_only=True):
        files = []
        cdef ArchiveSaveFile file
        cdef int i;
        for i in range(0, self.results.count):
            file = self.results.files[i]
            if changed_only:
                if file.has_changes:
                    files.append(file.filename)
            else:
                files.append(file.filename)
        return files


cdef extern from 'Archive.h':
    ctypedef struct Archive:
        pass


    void Archive_init(Archive* self,
                           const char* base_file_path)

    cdef void Archive_free(Archive* archive)

    cdef bint Archive_has(const Archive* archive,
                          const char* key)

    cdef Errors Archive_add_empty_page(Archive* archive)

    cdef Errors Archive_add_page_by_name(Archive* archive,
                                         const char* filename);


    cdef Errors Archive_save(const Archive*           self,
                            ArchiveSaveResult*       result);


cdef class ArchiveBackend:
    cdef Archive archive

    def __init__(self, str root_file_path, list pages):
        py_byte_string = root_file_path.encode('UTF-8')
        cdef char* file_path = py_byte_string
        Archive_init(&self.archive, base_file_path=file_path)
        for page in pages:
            self._add_page(page)

        if len(pages) == 0:
            self._add_empty_page()

    def get_archive(self):
        return <int>&self.archive

    def _add_page(self, str filename):
        py_byte_string = filename.encode('UTF-8')
        cdef char* file_path = py_byte_string
        raise_on_error(
            Archive_add_page_by_name(archive=&self.archive, filename=file_path)
        )

    def save(self, changed_only=True):
        files = ArchiveFiles()
        raise_on_error(Archive_save(&self.archive, &files.results))
        return files.to_list(changed_only=changed_only)

    def _add_empty_page(self):
        raise_on_error(
            Archive_add_empty_page(&self.archive)
        )




