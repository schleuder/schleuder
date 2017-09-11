#!/usr/bin/env python

"""
A small script to pull the Travis builds state and result for a given
commit.
"""

from os import environ
from requests import get
from sys import exit
from time import sleep


# The commit SHA we're interested in
COMMIT_SHA = environ['CI_COMMIT_SHA']
# The Travis URL we're checking for the state and result
TRAVIS_API_URL = 'https://api.travis-ci.org/repositories/schleuder/schleuder3/builds'
# The Travis URL to link to in case of build errors
TRAVIS_WEB_URL = 'https://travis-ci.org/schleuder/schleuder3/builds/{id}'


def travis_builds_details(state_or_result):
    # Get all Travis builds
    travis_builds = get(TRAVIS_API_URL).json()

    # Loop trough all builds up until we found the one we're interested in
    for build in travis_builds:
        if build['commit'] == COMMIT_SHA:
            # Return the details which we need for further processing
            return [build['id'], build[state_or_result]]


def main():
    # Sleep for 60 seconds to let Travis start the builds
    # Polling earlier doesn't make any sense
    sleep(60)

    # Check for the Travis builds state
    # As long as the state isn't 'finished', we need to wait
    # for the final result
    while travis_builds_details('state')[1] != 'finished':
        sleep(15)
        pass

    # Check the result and exit accordingly
    travis_result = travis_builds_details('result')

    if travis_result[1] == 0:
        print('Travis: passed')
        exit(0)

    else:
        print('Travis: failed')
        print(' '.join(['For details see:', TRAVIS_WEB_URL.format(id=travis_result[0])]))
        exit(1)


if __name__ == '__main__':
    main()
