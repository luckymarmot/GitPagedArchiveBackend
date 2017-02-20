import os
from binascii import unhexlify
from unittest import TestCase

import shutil
from pygit2 import GIT_FILEMODE_BLOB, Repository

from paged_archive._archive import ArchiveRepository


class TestInit(TestCase):
    def setUp(self):
        try:
            shutil.rmtree('./data')
        except FileNotFoundError:
            pass
        os.mkdir(os.path.abspath('./data/'))
        os.mkdir(os.path.join(os.path.abspath('./data/'), 'repo'))

    def test_init(self):
        repo = ArchiveRepository.from_path("/data/repo", "./data/", [])

        blob = repo.create_blob(
            b"data!1!"
        )

        treeb = repo.TreeBuilder()
        treeb.insert(
            'test',
             blob.hex,
             GIT_FILEMODE_BLOB
        )
        treeb.write()


