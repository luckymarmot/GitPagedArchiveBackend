from distutils.core import setup
from Cython.Build import cythonize
from Cython.Distutils import Extension
from pygit2._build import get_libgit2_paths


libgit2_bin, libgit2_include, libgit2_lib = get_libgit2_paths()
print(libgit2_lib, libgit2_include)
ex = Extension(
    '*', ['./src/*.pyx'],
    cython_c_in_temp=True,
    libraries=['git2'],
    include_dirs=[libgit2_include],
    library_dirs=[libgit2_lib]
)


extensions = [ex,]

setup(
    ext_modules=cythonize(extensions),
)
