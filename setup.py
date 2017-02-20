import setuptools
from distutils.core import setup


def ext_modules():
    from Cython.Build import cythonize
    from Cython.Distutils import Extension
    from pygit2._build import get_libgit2_paths

    libgit2_bin, libgit2_include, libgit2_lib = get_libgit2_paths()

    ex_archive = Extension(
        'paged_archive._archive',
        sources=[
            './src/_archive.pyx',
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

    extensions = [ex_archive, ]

    return cythonize(extensions)


class lazy_cythonize(list):
    def __init__(self, callback):
        self._list, self.callback = None, callback

    def c_list(self):
        if self._list is None: self._list = self.callback()
        return self._list

    def __iter__(self):
        for e in self.c_list(): yield e

    def __getitem__(self, ii):
        return self.c_list()[ii]

    def __len__(self):
        return len(self.c_list())


setup(
    name="paged_archive",
    ext_modules=lazy_cythonize(ext_modules),
    dependency_links=[
        'git+https://github.com/libgit2/pygit2.git@master'
    ],

    setup_requires=[
        'pygit2==0.25.0',
        'Cython==0.25.2'],
    install_requires=[
        'pygit2==0.25.0',
        'Cython==0.25.2'
    ],
    version='0.0.dev5',
    url='https://github.com/luckymarmot/GitPagedArchiveBackend',
    maintainer='Matthaus Woolard',
    maintainer_email="matt@paw.cloud",
    packages=['paged_archive']
)
