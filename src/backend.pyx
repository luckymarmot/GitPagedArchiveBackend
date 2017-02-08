# const char *host, *user, *passwd, *sql_db, *unix_socket;
# git_odb_backend *odb_backend = NULL;
# git_refdb_backend *refdb_backend = NULL;
# git_odb *odb = NULL;
# git_refdb *refdb = NULL;
# git_repository *repository = NULL;
# int portno, ret = GIT_OK;
#
# if (!PyArg_ParseTuple(args, "ssssiz", &host, &user, &passwd, &sql_db,
#           &portno, &unix_socket))
# return NULL;
#
# /* XXX -- allow for connection options such as compression and SSL */
# ret = git_odb_backend_mysql_open(&odb_backend, &refdb_backend, host, user,
#             passwd, sql_db, portno, unix_socket, 0);
# if (ret == GIT_ENOTFOUND) {
# PyErr_Format(PyExc_Exception, "No git db found in specified database");
# return NULL;
# } else if (ret < 0) {
# /* An error occurred -- XXX however there's currently no facility for
#  * identifying what error that is and telling the user about it, which is
#  * poor. For now, just raise a generic error */
# PyErr_Format(PyExc_Exception, "Failed to connect to mysql server");
# return NULL;
# }
#
# /* We have successfully created a custom backend. Now, create an odb around
# * it, and then wrap it in a repository. */
# ret = git_odb_new(&odb);
# if (ret != GIT_OK)
# goto cleanup;
#
# ret = git_odb_add_backend(odb, odb_backend, 0);
# if (ret != GIT_OK)
# goto cleanup;
#
# ret = git_repository_wrap_odb(&repository, odb);
# if (ret != GIT_OK)
# goto cleanup;
#
# /* Create a new reference database obj, add our custom backend, shoehorn into
# * repository */
# ret = git_refdb_new(&refdb, repository);
# if (ret != GIT_OK)
# goto cleanup;
#
# ret = git_refdb_set_backend(refdb, refdb_backend);
# if (ret != GIT_OK)
# goto cleanup;
#
# /* Can't fail */
# git_repository_set_refdb(repository, refdb);
#
# /* Decrease reference count on both refdb and odb backends -- they'll be
# * kept alive, but only by one reference, held by the repository */
# git_refdb_free(refdb);
# git_odb_free(odb);
#
# /* On success, return a PyCapsule containing the created repo.
# * No destructor, manual deallocation occurs */

from cpython.pycapsule cimport PyCapsule_New, PyCapsule_GetPointer
from archive cimport ArchiveBackend



cdef class Backend:
    def __init__(self, ArchiveBackend archive):
        self.backend = PyCapsule_New(*archive.archive, 'backend', NULL)

    def build_backend(self, ArchiveBackend archive, str path):

         cdef git_odb_backend *odb_backend = NULL;
         cdef git_refdb_backend *refdb_backend = NULL;
         cdef git_odb *odb = NULL;
         cdef git_refdb *refdb = NULL;
         cdef git_repository *repository = NULL;
         cdef int portno, ret = GIT_OK;
