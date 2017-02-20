# GitPagedArchiveBackend
Git ODB backend for [libgit2](https://github.com/libgit2/libgit2) and [pyGit2](https://github.com/libgit2/pygit2) to save data in a set of packed binary files.

## Use Case
This backend aims for server side git repos with many small objects that needs to be movevle into cold storage and then quickly restored.

Key issues this backend helps with:

### Loading a cold repo out of storage
The fs odb solution does have a packed format however one will typically still have many small files, this produces a high io overhead for small files.
The layered solution allows the loading of a small number of layers (2000 objects per layer)

### On write quickly sending a minimal amount of data so a storage api that has call based charging (eg s3)
On write the new layers are reported these can then be pushed to a save storage location allowing the repo servers to be stateless compared to tradition git fs this is also a much lower io cost of looping of all files and packing up/detecting changes.

### Optimised operations for multiple incoming concurrent reads on the same python posses.
Since the PagedArchive object can be kept im memory and reused on different instances of the Repo class the optimsation of keeping the lookup table in memory significantly speeds things up compared to io bound operations. This is useful on servers with limited io budgets.


## Compile
```bash
python setup.py build_ext --inplace
```

## Install
```bash
python setup.py install
```

