//
// Created by Matthaus Woolard on 08/02/2017.
//

#ifndef LIBGIT2_ARCHIVE_GITBACKEND_H
#define LIBGIT2_ARCHIVE_GITBACKEND_H
#include <Python.h>

int attach_archive_to_repo(git_repository* repo, Archive* archive);
int clone_object(PyObject* source_repo, PyObject* target_repo, const char* hex);

#endif //LIBGIT2_ARCHIVE_GITBACKEND_H
