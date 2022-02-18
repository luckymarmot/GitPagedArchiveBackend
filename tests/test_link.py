import pygit2._pygit2 as _pygit2
import os
import shutil
import uuid
from unittest import TestCase

from paged_archive._archive import ArchiveRepository, clone_repo_object, init_libgit2
from pygit2 import GIT_FILEMODE_BLOB, init_repository, Signature


class TestInit(TestCase):
    def setUp(self):
        try:
            shutil.rmtree('./data')
        except FileNotFoundError:
            pass
        os.mkdir(os.path.abspath('./data/'))
        os.mkdir(os.path.join(os.path.abspath('./data/'), 'repo'))
        self._repo_path = os.path.join(os.path.abspath('./data/'), 'repo')
        self._data_path = os.path.abspath('./data/')
        self._classic_repo = init_repository(
            os.path.join(os.path.abspath('./data/'), 'repo'),
            bare=True
        )
        init_libgit2()

    def tearDown(self):
        try:
            shutil.rmtree('./data')
        except FileNotFoundError:
            pass

    def test_init(self):
        repo = ArchiveRepository.from_path(
            f"{self._repo_path}/", self._data_path,
            []
        )

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

    def test_copy(self):
        blob = self._classic_repo.create_blob(
            b'test data inset'
        )

        target_repo = ArchiveRepository.from_path(
            self._repo_path, self._data_path,
            []
        )

        clone_repo_object(
            self._classic_repo,
            target_repo,
            blob.hex
        )

        new_blob = target_repo[blob.hex]

        self.assertEqual(new_blob.data, b'test data inset')

    def test_mass_clone(self):
        objects = {}
        for _ in range(20000):
            data = uuid.uuid4().bytes
            b = self._classic_repo.create_blob(
                data
            )
            objects[b.hex] = data

        target_repo = ArchiveRepository.from_path(
            self._repo_path, self._data_path,
            []
        )

        for hex in objects.keys():
            clone_repo_object(
                self._classic_repo,
                target_repo,
                hex
            )

        for hex, value in objects.items():
            blob = target_repo[hex]
            self.assertEqual(blob.hex, hex)
            self.assertEqual(blob.data, value)

        layers = target_repo.backend_archive.save()

        target_repo = ArchiveRepository.from_path(
            self._repo_path,
            self._data_path,
            layers=list(layers.keys())
        )

        self.assertEqual(len(layers), 10)

        for hex, value in objects.items():
            blob = target_repo[hex]
            self.assertEqual(blob.hex, hex)
            self.assertEqual(blob.data, value)

    def test_commit_clone(self):
        """
            
        Test that object types are preserved
        
        :return: 
        """
        tree = self._classic_repo.TreeBuilder()
        tree.insert(
            'testobj', self._classic_repo.create_blob(b'testdata'),
            GIT_FILEMODE_BLOB
        )
        tree_oid = tree.write()

        commit = self._classic_repo.create_commit(
            'HEAD',
            Signature('Paw Inc', '0+none@user.paw'),
            Signature('Paw Inc', '0+none@user.paw'),
            'testcommit', tree_oid, []
        )

        target_repo = ArchiveRepository.from_path(
            self._repo_path, self._data_path,
            []
        )

        with self.assertRaises(KeyError):
            target_repo[commit.hex]

        clone_repo_object(
            self._classic_repo,
            target_repo,
            commit.hex
        )

        commit = target_repo[commit.hex]

        with self.assertRaises(_pygit2.GitError):
            # tree as not been copied :)
            commit.tree

        clone_repo_object(
            self._classic_repo,
            target_repo,
            tree_oid.hex
        )

        tree = commit.tree

        for tree_entry in tree:  # type: 'pygit2.TreeEntry'
            with self.assertRaises(KeyError):
                target_repo[tree_entry.oid]
            clone_repo_object(
                self._classic_repo,
                target_repo,
                tree_entry.oid.hex
            )
            item = target_repo[tree_entry.oid]
            self.assertEqual(item.data, b'testdata')

    def test_copy_fail(self):
        blob = self._classic_repo.create_blob(
            b'test data inset'
        )

        target_repo = ArchiveRepository.from_path(
            self._repo_path, self._data_path,
            []
        )

        hex = blob.hex

        with self.assertRaises(KeyError):
            clone_repo_object(
                self._classic_repo,
                target_repo,
                hex[::-1]
            )
        with self.assertRaises(KeyError):
            target_repo[blob.hex]



