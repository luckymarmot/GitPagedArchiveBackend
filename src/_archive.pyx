from collections import OrderedDict
from typing import List

from cpython.pycapsule cimport PyCapsule_New, PyCapsule_Destructor, \
   PyCapsule_GetPointer
from pygit2.repository import BaseRepository

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

    def to_dict(self):
        files = OrderedDict()
        cdef bytes py_string
        cdef ArchiveSaveFile file
        cdef int i;
        for i in range(0, self.results.count):
            file = self.results.files[i]
            py_string = file.filename
            files[py_string.decode('utf-8')] = file.has_changes
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


cdef class PagedArchive:
    cdef Archive archive
    def __init__(self, str root_file_path: str, list pages: str) -> None:
        """
        Create an archive
        
        
        :param root_file_path: Project root, the root dir to all the pages
        :type root_file_path: str
        :param pages: List of paths to the layers in order (last is top layer)
        :type pages: list
        """
        py_byte_string = root_file_path.encode('UTF-8')
        cdef char* file_path = py_byte_string
        Archive_init(&self.archive, base_file_path=file_path)
        for page in pages:
            self._add_page(page)

        if len(pages) == 0:
            self._add_empty_page()

    def _add_page(self, str filename: str) -> None:
        """
        Add a page to the end of the list of archive
        
        :param filename: The file path to the new page
        :type filename: str
        """
        py_byte_string = filename.encode('UTF-8')
        cdef char* file_path = py_byte_string
        raise_on_error(
            Archive_add_page_by_name(archive=&self.archive, filename=file_path)
        )

    def save(self) -> dict:
        """
        Save any changes to disk and return a dict mapping layer name to bool
        of indicating if there were changes to save.
        
        :return: dict of filenames mapping ot changes
        """
        files = ArchiveFiles()
        raise_on_error(Archive_save(&self.archive, &files.results))
        return files.to_dict()

    def has(self, bytes key: bytes) -> bool:
        """
        Test if a given key is found in the archive
        
        :param key: 20 char key are raw bytes (not hex)
        :type key: bytes
        :return: True if in the pages False otherwise
        :rtype: bool
        """
        if len(key) != 20:
            raise ValueError('Key must be 20 chars')
        cdef char* b_key = key
        return Archive_has(&self.archive, key=b_key)

    def __contains__(self, bytes key: bytes) -> bool:
        """
        Check if key in 
        
        :param key: 20 char key are raw bytes (not hex)
        :type key: bytes
        :return: True if in the pages False otherwise
        :rtype: bool
        """
        return self.has(key)

    cpdef bytes get(self, bytes key):
        """
        Get the data for a key
        
        :param key: 20 char key are raw bytes (not hex)
        :type key: bytes
        :return: the data
        :rtype: bool
        """
        if len(key) != 20:
            raise ValueError('Key must be 20 chars')
        cdef char* b_key = key
        cdef char* data = NULL
        cdef size_t size = 0
        raise_on_error(
            Archive_get(&self.archive, key=b_key, _data=&data, _data_size=&size)
        )
        cdef bytes py_string = data[:size]
        return py_string

    def __getitem__(self, bytes key: bytes) -> bytes:
        """
        Get the data for a key
        
        :param key: 20 char key are raw bytes (not hex)
        :type key: bytes
        :return: the data
        :rtype: bool
        """
        return self.get(key=key)

    def set(self, bytes key: bytes, bytes data: bytes) -> None:
        """
        Set data for a given key
        
        :param key: 20 char key are raw bytes (not hex)
        :type key: bytes
        :param data: the data to set encoded in bytes
        :type data: bytes
        """
        if len(key) != 20:
            raise KeyError('Key must be 20 chars')
        cdef char* b_key = key
        cdef char* _data = data
        raise_on_error(
            Archive_set(&self.archive, b_key, _data, len(data))
        )

    def __setitem__(self, bytes key: bytes, bytes data: bytes) -> None:
        """
        Set data for a given key
        
        :param key: 20 char key are raw bytes (not hex)
        :type key: bytes
        :param data: the data to set encoded in bytes
        :type data: bytes
        """
        self.set(key=key, data=data)

    def _add_empty_page(self) -> None:
        """
        Init a new page to the archive
        """
        raise_on_error(
            Archive_add_empty_page(&self.archive)
        )

    def __dealloc__(self):
        """
        Free the archive
        """
        Archive_free(&self.archive)


cdef extern from 'git2/repository.h':
    ctypedef struct git_repository
    int git_repository_open(git_repository** repo_out, const char* path)
    void git_repository_free(git_repository* repo)


cdef extern from 'gitbackend.h':
    int attach_archive_to_repo(git_repository* repo, Archive* archive);


# Destructor for cleaning up Point objects
cdef del_Backend(object obj):
    """
    We do not do any clean up here since python gc cleans this up from
    elsewhere
    """
    pass



class _Backend:
    def __init__(self,
                 PagedArchive archive: PagedArchive,
                 str path: str) -> None:
        """
        Create a backend object
        
        :param archive: Archive to be used for this backend
        :type archive: PagedArchive
        :param path: path to the refs for this git repo
        :type path: str
        """
        self.backend = self.build_backend(archive=archive, str_path=path)
        self.archive = archive

    def build_backend(self,
                      PagedArchive archive: PagedArchive,
                      str str_path: str) -> object:
        """
        
        :param archive: Archive to be used for this backend
        :type archive: PagedArchive
        :param str_path: path to the refs for this git repo
        :type str_path: str
        :return: a python capsule of the pointer to the backend struct
        :rtype: object
        """
        py_byte_string = str_path.encode('UTF-8')
        cdef const char* path = py_byte_string
        cdef git_repository *repository = NULL;
        cdef int err = git_repository_open(&repository, path)
        if err < 0:
            git_repository_free(repository)
            raise Exception("could not open the repo error {}".format(err))

        err = attach_archive_to_repo(repository, &archive.archive)

        if err < 0:
            git_repository_free(repository)
            raise Exception("could not open the repo error {}".format(err))

        return PyCapsule_New(
            <void*> repository, "backend", <PyCapsule_Destructor>del_Backend)



class ArchiveRepository(BaseRepository):
    def __init__(self,
                 str repo_path: str,
                 PagedArchive archive: PagedArchive,
                 *args, **kwargs):
        """
        Open a ArchiveRepository given a 
        
        :param repo_path: path to the refs for this repo
        :type repo_path: str
        :param archive: archive for this repo
        :type archive: PagedArchive
        """
        self.__archive = archive
        self.__repo_path = repo_path
        self.__backend = _Backend(self.__archive, repo_path)
        super().__init__(backend=self.__backend.backend, *args, **kwargs)

    @classmethod
    def from_path(cls,
                  str repo_path: str,
                  str root_path: str,
                  list layers: List[str]) -> 'ArchiveRepository':
        """
        Open a new repo based on a location
        
        :param repo_path: Path to the refs
        :param root_path: Path to the layers
        :param layers: List of paths to the layers relative `root_path`
        :return: The new ArchiveRepository
        :type: ArchiveRepository
        """
        archive = PagedArchive(root_path, layers)

        return cls(repo_path, archive)

    @property
    def backend_archive(self) -> PagedArchive:
        """
        :return: The archive for this repo
        :rtype: PagedArchive
        """
        return self.__archive
