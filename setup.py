from distutils.command import build_clib, build_ext
from distutils.core import setup
from Cython.Build import cythonize
from Cython.Distutils import Extension
from pygit2._build import get_libgit2_paths


libgit2_bin, libgit2_include, libgit2_lib = get_libgit2_paths()


ex = Extension(
    'backend',
    sources= ['./src/backend.pyx',
              './src/ArchiveLib/archive/Archive.c',
            './src/ArchiveLib/archive/ArchivePage.c',
            './src/ArchiveLib/archive/HashIndex.c',
            './src/ArchiveLib/archive/HashIndexPack.c'],
    cython_c_in_temp=True,
    libraries=['git2'],
    include_dirs=[libgit2_include, './src/ArchiveLib/archive'],
    library_dirs=[libgit2_lib]
)


extensions = [ex,]

setup(
    ext_modules=cythonize(extensions),
)
