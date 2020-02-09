#
# this is the package version number
#
__version__ = '1.0.2'

#
# a few different components in this project need to make
# sure they use the same version of Clair and hence the
# motivation for having __clair_version__
#
# see https://quay.io/repository/coreos/clair?tab=tags
#
__clair_version__ = 'v2.1.2'

#
# Given the Clair version is declared above might as well
# keep the postgres version nearby too.
#
# see
#   https://hub.docker.com/_/postgres
#   https://www.postgresql.org/support/versioning/
#   http://www.postgresql.org/docs/9.5/static/libpq-connect.html#LIBPQ-CONNSTRING
#   https://www.postgresql.org/docs/12/libpq-connect.html#LIBPQ-CONNSTRING
#
__postgres_version__ = '12.1'
