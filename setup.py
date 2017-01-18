from distutils.core import setup
from Cython.Build import cythonize
from Cython.Distutils import Extension

ex = Extension('*', ['./src/*.pyx'], cython_c_in_temp=True)

extensions = [ex,]

setup(
    ext_modules=cythonize(extensions)
)
