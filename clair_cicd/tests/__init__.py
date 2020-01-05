import unittest

from .. import __version__
from .. import __clair_version__


class SomethingTestCase(unittest.TestCase):

    def test_version(self):
        self.assertIsNotNone(__version__)
        self.assertTrue(0 < len(__version__))

    def test_clair_version(self):
        self.assertIsNotNone(__clair_version__)
        self.assertTrue(0 < len(__clair_version__))
