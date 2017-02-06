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
    if error == E_SUCCESS:
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

    def __dealloc__(self):
        ArchiveSaveResult_free(&self.results)


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


    Errors Archive_save(const Archive*           self,
                        ArchiveSaveResult*       result);

    Errors Archive_get(const Archive*            self,
                       const char*               key,
                       char**                    _data,
                       size_t*                   _data_size);

    Errors      Archive_set(Archive*              self,
                        const char*               key,
                        const char*               data,
                        size_t                    size);


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

    def has(self, str key):
        py_byte_string = key.encode('UTF-8')
        if len(py_byte_string) != 20:
            raise KeyError('Key must be 20 chars')
        cdef char* b_key = py_byte_string
        return Archive_has(&self.archive, key=b_key)

    def __contains__(self, str key):
        return self.has(key)

    cpdef bytes get(self, str key):
        py_byte_string = key.encode('UTF-8')
        if len(py_byte_string) != 20:
            raise KeyError('Key must be 20 chars')
        cdef char* b_key = py_byte_string
        cdef char* data = NULL
        cdef size_t size = 0
        raise_on_error(
            Archive_get(&self.archive, key=b_key, _data=&data, _data_size=&size)
        )
        cdef bytes py_string = data[:size]
        return py_string

    def __getitem__(self, str key):
        return self.get(key=key)

    def set(self, str key, bytes data):
        py_byte_string = key.encode('UTF-8')
        if len(py_byte_string) != 20:
            raise KeyError('Key must be 20 chars')
        cdef char* b_key = py_byte_string
        cdef char* _data = data
        raise_on_error(
            Archive_set(&self.archive, b_key, _data, len(data))
        )

    def __setitem__(self, str key, bytes data):
        self.set(key=key, data=data)

    def _add_empty_page(self):

        raise_on_error(
            Archive_add_empty_page(&self.archive)
        )

    def __dealloc__(self):
        Archive_free(&self.archive)
