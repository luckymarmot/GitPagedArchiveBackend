from unittest import TestCase
from pygit2.repository import BaseRepository
from pygit2 import GIT_FILEMODE_BLOB

from paged_archive import ArchiveRepository


class TestInit(TestCase):
    def test_init(self):
        print("pre archive init")
        print("archive inited")

        repo = ArchiveRepository.from_path("/tmp/testrepo", "./data/", [])
        archive = repo.backend_archive
        print("backend online")


        print("repo created online")

        print("writing blob")
        blob = repo.create_blob(
            b"data!1!"
        )
        print("blob writen")

        treeb = repo.TreeBuilder()
        treeb.insert(
            'test',
             blob.hex,
             GIT_FILEMODE_BLOB
        )
        treeb.write()
        print(blob.raw)
        print(blob.hex)
        from binascii import unhexlify
        b = unhexlify(blob.hex)
        print(b)
        self.assertTrue(archive.has(b))
        self.assertEqual(archive.get(b)[4:], b"data!1!")
        self.assertTrue(blob.hex[:-3] in repo)

        bl = repo[blob.hex[:-1]]

        archive.save()





