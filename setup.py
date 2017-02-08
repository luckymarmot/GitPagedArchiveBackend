from distutils.command import build_clib, build_ext
from distutils.core import setup
from Cython.Build import cythonize
from Cython.Distutils import Extension
from pygit2._build import get_libgit2_paths

libgit2_bin, libgit2_include, libgit2_lib = get_libgit2_paths()

ex_archive = Extension(
    name='paged_archive',
    sources=[
             './src/paged_archive.pyx',
             './src/gitbackend.c',
             './src/ArchiveLib/archive/Archive.c',
             './src/ArchiveLib/archive/ArchivePage.c',
             './src/ArchiveLib/archive/HashIndex.c',
             './src/ArchiveLib/archive/HashIndexPack.c'
    ],
    cython_c_in_temp=True,
    libraries=['git2'],
    include_dirs=[libgit2_include, './src/ArchiveLib/archive'],
    library_dirs=[libgit2_lib]
)

extensions = [ex_archive,]

setup(
    name="paged_archive",
    ext_modules=cythonize(extensions),
)
