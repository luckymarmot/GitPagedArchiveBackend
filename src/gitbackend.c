//
// Created by Matthaus Woolard on 06/02/2017.
//


#include <assert.h>
#include <fcntl.h>
#include <string.h>
#include <limits.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <git2.h>
#include <git2/oid.h>
#include <git2/odb_backend.h>
#include <git2/refs.h>
#include <git2/sys/odb_backend.h>
#include <git2/sys/refdb_backend.h>
#include <git2/sys/refs.h>
#include <git2/sys/repository.h>
#include <git2/errors.h>
#include <git2/types.h>
#include <git2/indexer.h>
#include <git2/repository.h>
#include "Archive.h"
#include "Errors.h"

typedef struct ArchiveODBBackend {
    git_odb_backend parent;
    Archive *archive;
} ArchiveODBBackend;





typedef struct __attribute__((__packed__)) PackedData {
    git_otype type;
    char data[];
} PackedData;


static inline git_error_code convert_to_git_error(Errors error) {
    switch(error) {
        case E_SUCCESS:
            return GIT_OK;

        case E_NOT_FOUND:
            return GIT_ENOTFOUND;

        default :
            return GIT_ERROR;
    }

}

/**
 *
 * Read the header
 *
 * @param len_p
 * @param type_p
 * @param _backend
 * @param oid
 * @return
 */
static int archive_odb_backend__read_header(size_t *len_p,
                                            git_otype *type_p,
                                            git_odb_backend *_backend,
                                            const git_oid *oid)
{
    ArchiveODBBackend*  backend = (ArchiveODBBackend*) _backend;
    Archive* archvie = backend->archive;

    char* data;
    size_t size;

    Errors e = Archive_get_partial(
            archvie, (const char *) oid->id,
            GIT_OID_RAWSZ, NULL,
            sizeof(git_otype),
            &data,
            &size
    );

    if (e != E_SUCCESS) {
        return convert_to_git_error(e);
    }

    PackedData* p_data = (PackedData*) data;
    *type_p = p_data->type;

    free(data);

    return GIT_OK;
}


/**
 *
 * read_prefix
 *
 * @param output_oid
 * @param out_buf
 * @param out_len
 * @param out_type
 * @param _backend
 * @param partial_oid
 * @param oidlen
 * @return
 */
static int archive_odb_backend__read_prefix(git_oid *output_oid, void **out_buf,
                                          size_t *out_len, git_otype *out_type, git_odb_backend *_backend,
                                          const git_oid *partial_oid, size_t oidlen)
{
    ArchiveODBBackend*  backend = (ArchiveODBBackend*) _backend;
    Archive* archvie = backend->archive;


    char* data;
    size_t size;


    Errors e = Archive_get_partial(
            archvie, (const char *) partial_oid->id,
            oidlen/2, (char *) &(output_oid->id)[0],
            0,
            &data,
            &size);
    if (e != E_SUCCESS)
    {
        return convert_to_git_error(e);
    }

    void* output_data = git_odb_backend_malloc(_backend, size);

    PackedData* p_data = (PackedData*) data;
    *out_len = size - sizeof(git_otype);

    memcpy(output_data, p_data->data, *out_len);

    *out_type = p_data->type;

    *out_buf = output_data;

    free(data);

    return GIT_OK;
}


/**
 *
 * Read
 *
 * @param data_p
 * @param len_p
 * @param type_p
 * @param _backend
 * @param oid
 * @return
 */
static int archive_odb_backend__read(
        void **data_p,
        size_t *len_p,
        git_otype *type_p,
        git_odb_backend *_backend,
        const git_oid *oid) {

    ArchiveODBBackend *backend = (ArchiveODBBackend *) _backend;
    Archive *archvie = backend->archive;

    char *data;
    size_t size;


    Errors e = Archive_get(
            archvie, (const char *) oid->id,
            &data,
            &size);

    if (e != E_SUCCESS) {
        return convert_to_git_error(e);
    }

    void *output_data = git_odb_backend_malloc(_backend, size);

    PackedData *p_data = (PackedData *) data;
    *len_p = size - sizeof(git_otype);

    memcpy(output_data, p_data->data, *len_p);

    *type_p = p_data->type;

    *data_p = output_data;

    free(data);

    return GIT_OK;
}

static int archive_odb_backend__exists(git_odb_backend *_backend, const git_oid *oid)
{
    ArchiveODBBackend *backend = (ArchiveODBBackend *) _backend;
    Archive *archvie = backend->archive;

    bool found = Archive_has(
            archvie, (const char *) oid->id
    );

    if (found) {
        return 1;
    }

    return 0;
}


static int archive_odb_backend__exists_prefix(git_oid * output_oid, git_odb_backend * _backend, const git_oid * oid,
                                              size_t oidlen)

{
    ArchiveODBBackend *backend = (ArchiveODBBackend *) _backend;
    Archive *archvie = backend->archive;

    bool found = Archive_has_partial(
            archvie,
            (const char *) oid->id,
            oidlen,
            (char *) output_oid->id
    );

    if (found) {
        return 1;
    }

    return 0;
}


static int archive_odb_backend__write(
        git_odb_backend *_backend,
        const git_oid *oid,
        const void *data,
        size_t len,
        git_otype type)
{
    ArchiveODBBackend *backend = (ArchiveODBBackend *) _backend;
    Archive *archvie = backend->archive;



    PackedData *p_data = (PackedData *) malloc(sizeof(PackedData) + len);
    p_data->type = type;
    memcpy(p_data->data, data, len);

    Errors e = Archive_set(
            archvie, (const char *) oid->id,
            (const char *) p_data,
            sizeof(PackedData) + len
    );

    free(p_data);
    return convert_to_git_error(e);
}

static void archive_odb_backend__free(git_odb_backend *_backend)
{
}


void git_odb_backend_archive_free(git_odb_backend *backend)
{
    return;
}


int git_odb_backend_archive_open(git_odb_backend **odb_out,
                                 Archive* archive)
{
    ArchiveODBBackend *odb_backend;


    odb_backend = calloc(1, sizeof(ArchiveODBBackend));
    if (odb_backend == NULL) {
        giterr_set_oom();
        return GIT_ERROR;
    }

    /* Create two connections, one for odb access, the other for refdb. This
     * simplifies situations where, perhaps, a refdb_backend is freed but the
     * odb_backend continues elsewhere. */
    odb_backend->archive = archive;

    odb_backend->parent.version = GIT_ODB_BACKEND_VERSION;
    odb_backend->parent.odb = NULL;
    odb_backend->parent.read = &archive_odb_backend__read;
    odb_backend->parent.read_header = &archive_odb_backend__read_header;
    odb_backend->parent.read_prefix = &archive_odb_backend__read_prefix;
    odb_backend->parent.write = &archive_odb_backend__write;
    odb_backend->parent.exists = &archive_odb_backend__exists;
    odb_backend->parent.exists_prefix = &archive_odb_backend__exists_prefix;
    odb_backend->parent.free = &git_odb_backend_archive_free;
    *odb_out = (git_odb_backend *)odb_backend;
    return GIT_OK;
}


int attach_archive_to_repo(git_repository* repo, Archive* archive) {

    git_odb_backend* odb_backend = NULL;

    int er = git_odb_backend_archive_open(&odb_backend, archive);
    if (er < 0) {
        return er;
    }
    git_odb *odb = NULL;
    er = git_odb_new(&odb);
    if (er < 0) {
        return er;
    }
    er = git_odb_add_backend(odb, odb_backend, 0);
    if (er < 0) {
		git_odb_free(odb);
        return er;
    }

    git_repository_set_odb(repo, odb);

    git_odb_free(odb);
    return er;
}


int init_repo(git_repository** repo, char* path, Archive* archive) {
	int er = git_repository_open(repo, path);
    if (er < 0) {
        return er;
    }
    return attach_archive_to_repo(*repo, archive);
}

#include <Python.h>

typedef struct CRepository {
    PyObject_HEAD
    git_repository* repo;
    PyObject *index;  /* It will be None for a bare repository */
    PyObject *config; /* It will be None for a bare repository */
    int owned;    /* _from_c() sometimes means we don't own the C pointer */
} CRepository;


int clone_object(PyObject* source_repo_object, PyObject* target_repo_object, const char* hex) {
    git_odb* source_odb;
    git_odb* target_odb;
    git_repository* source_repo = ((CRepository*) source_repo_object)->repo;
    git_repository* target_repo = ((CRepository*) target_repo_object)->repo;
    int error = git_repository_odb(&source_odb, source_repo);
    if (error < 0) {
        return error;
    }
    error = git_repository_odb(&target_odb, target_repo);
    if (error < 0) {
        return error;
    }
    git_oid oid;

    error = git_oid_fromstrp(&oid, hex);
    // This is should be a null ended string Cython will convert to this from python unicode string.
    if (error < 0) {
        return error;
    }

    git_odb_object* object;


    // Read the object from the current db
    error = git_odb_read(&object, source_odb, &oid);
    if (error < 0) {
        return error;
    }

    const void* data = git_odb_object_data(object);

    size_t size = git_odb_object_size(object);

    git_otype type = git_odb_object_type(object);

    git_oid new_oid;

    error = git_odb_write(&new_oid, target_odb, data, size, type);
    if (error < 0) {
        return error;
    }

    if (memcmp(new_oid.id, oid.id, 20 * sizeof(char)) != 0) {
        return -1;
    }


    if (git_odb_exists(target_odb, &oid) != 1) {
        return -1;
    }

    git_odb_object_free(object);
    return 0;
}
