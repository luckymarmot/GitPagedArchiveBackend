from unittest import TestCase

import shutil
from pygit2 import GIT_FILEMODE_BLOB, Repository

from paged_archive import ArchiveRepository


class TestInit(TestCase):
    def setUp(self):
        shutil.rmtree('./data/repo')
        repo = Repository('./data/repo')


    def test_init(self):
        print("pre archive init")
        print("archive inited")

        repo = ArchiveRepository.from_path("/data/repo", "./data/", [])
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
        print("Reading...")
        self.assertTrue(blob.hex[:-3] in repo)
        print("read")

        repo[blob.hex[:-1]]
        hex = blob.hex
        files = archive.save()
        print(files)
        print('Saved')
        repo = ArchiveRepository.from_path("/tmp/testrepo", "./data/",
                                           [f.decode('utf-8')[7:] for f in files])
        print('new repo')
        archive = repo.backend_archive
        print('archive!')
        print(blob)
        print('hello', hex, repo)
        self.assertEqual(archive[unhexlify(repo[hex].hex)][4:], b"data!1!")
        print("Ok we are good?")
        'de021111' in repo
        print('new ass')
        print(archive)


