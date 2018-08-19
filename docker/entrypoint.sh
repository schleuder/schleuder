#!/bin/bash

#
# entrypoint script for schlocker
#

# handle signals
trap abort SIGHUP SIGINT SIGQUIT SIGTERM SIGSTOP SIGKILL
function abort {
    echo
    echo "* * * ABORTED * * *"
    echo
    exit 0
}

# homedir of the schlocker user
[ -z ${SCHLOCKER_HOMEDIR+x} ] && SCHLOCKER_HOMEDIR="/var/schlocker"

# what to watch
[ -z ${SCHLOCKER_MAILDIR+x} ] && SCHLOCKER_MAILDIR="$SCHLOCKER_HOMEDIR/mail"
# who to run as
[ -z ${SCHLOCKER_USER+x} ]  && SCHLOCKER_USER="schlocker"
[ -z ${SCHLOCKER_GROUP+x} ] && SCHLOCKER_GROUP="schlocker"

# config stuff
[ -z ${SCHLOCKER_CONFIG_PATH+x} ]        && SCHLOCKER_CONFIG_PATH="/etc/schleuder/schleuder.yml"
[ -z ${SCHLOCKER_CONFIG_SUPERADMIN+x} ]  && SCHLOCKER_CONFIG_SUPERADMIN="root@localhost"
[ -z ${SCHLOCKER_CONFIG_LISTS_DIR+x} ]   && SCHLOCKER_CONFIG_LISTS_DIR="$SCHLOCKER_HOMEDIR/lists"
[ -z ${SCHLOCKER_CONFIG_KEYWORD_HANDLERS_DIR+x} ] && SCHLOCKER_CONFIG_KEYWORD_HANDLERS_DIR="/usr/local/lib/schleuder/keyword_handlers"
[ -z ${SCHLOCKER_CONFIG_LOG_LEVEL+x} ]   && SCHLOCKER_CONFIG_LOG_LEVEL="warn"
[ -z ${SCHLOCKER_CONFIG_SMTP_HOST+x} ]   && SCHLOCKER_CONFIG_SMTP_HOST="localhost"
[ -z ${SCHLOCKER_CONFIG_SMTP_PORT+x} ]   && SCHLOCKER_CONFIG_SMTP_PORT="25"
# db settings
[ -z ${SCHLOCKER_DB_ADAPTER+x} ]  && SCHLOCKER_DB_ADAPTER="sqlite3"
[ -z ${SCHLOCKER_DB_DATABASE+x} ] && SCHLOCKER_DB_DATABASE="$SCHLOCKER_HOMEDIR/db.sqlite3"
# these are unused by default, only useful with mysql/postgresql/etc
[ -z ${SCHLOCKER_DB_ENCODING+x} ] && SCHLOCKER_DB_ENCODING=""
[ -z ${SCHLOCKER_DB_USERNAME+x} ] && SCHLOCKER_DB_USERNAME=""
[ -z ${SCHLOCKER_DB_PASSWORD+x} ] && SCHLOCKER_DB_PASSWORD=""
[ -z ${SCHLOCKER_DB_HOST+x} ]     && SCHLOCKER_DB_HOST=""

# hostname for schleuder lists
[ -z ${SCHLOCKER_HOSTNAME+x} ] && SCHLOCKER_HOSTNAME="$( hostname )"
# temp directory
# NOTICE: has to be on the same filesystem as maildirs
[ -z ${SCHLOCKER_TMPDIR+x} ]   && SCHLOCKER_TMPDIR="$SCHLOCKER_MAILDIR/.tmp"

#
# inform
echo "+-- working with:"
echo "    +-- SCHLOCKER_HOMEDIR  : $SCHLOCKER_HOMEDIR"
echo "    +-- SCHLOCKER_MAILDIR  : $SCHLOCKER_MAILDIR"
echo "    +-- SCHLOCKER_USER     : $SCHLOCKER_USER"
echo "    +-- SCHLOCKER_GROUP    : $SCHLOCKER_GROUP"
echo "    +-- SCHLOCKER_HOSTNAME : $SCHLOCKER_HOSTNAME"
echo "    +-- SCHLOCKER_TMPDIR   : $SCHLOCKER_TMPDIR"


#
# this waits for changes in $SCHLOCKER_MAILDIR directory
# and shoves any new messages into schleuder
#
# TODO: this has to be more sphisticated to handle traffic larger than just testing!
function watch_maildir {

    # inform
    echo "+-- watching for changes in Maildir at: $SCHLOCKER_MAILDIR"

    # loopy-loop!
    # signals handled by trap
    while true; do
        # wait for events
        # we're only interested in "move", as this is what happens when a complete message
        # gets put in */new
        # we won't catch ourselves moving stuff around, as when we're doing that,
        # inotifywait is not running
        # --format '%w%f' also not required, we're handling all the files hat we can find anyway
        inotifywait -r -e move -qq "$SCHLOCKER_MAILDIR"

        # if a watched event occurred, send the signal
        # done *after* we spot a new file
        # we can spare the short delay imposed
        # in return we are sure we actually have some directories to work on
        if [ $? -eq 0 ]; then
            # inform
            echo "    +-- Maildir modified, new message(s)!..."
            # make sure the required directories exist
            for d in "$SCHLOCKER_MAILDIR"/*; do
                # we need the basename
                bd="$( basename $d )"
                # and we need the tempdir to exist
                if [ ! -d "$SCHLOCKER_TMPDIR/$bd" ]; then
                    mkdir -p "$SCHLOCKER_TMPDIR/$bd"
                    chown -R "$SCHLOCKER_USER:$SCHLOCKER_GROUP" "$SCHLOCKER_TMPDIR/$bd"
                fi
                # move the files out of the way
                # this is done to let the mailserver continue its work while
                # the mails are being handled by schleuder
                find "$d/new" -type f -exec mv '{}' "$SCHLOCKER_TMPDIR/$bd/" \;
                # handle them
                for f in "$SCHLOCKER_TMPDIR/$bd"/*; do
                    # TODO: this will not remove failed messages
                    # TODO: we need better handling of failed messages
                    echo "        +-- calling schleuder for $bd@$SCHLOCKER_HOSTNAME file $f"
                    su -p -c "PATH=\"$PATH\" BUNDLE_PATH=\"$BUNDLE_PATH\" schleuder work $bd@$SCHLOCKER_HOSTNAME" "$SCHLOCKER_USER" < "$f" && rm "$f"
                done
            done
        fi
    done
}


#
# root is not what we want as the user to run as
#

# let's make sure we're not running as root, shall we?
if [ "$SCHLOCKER_UID" == "0" ] || [ "$SCHLOCKER_USER" == "root" ] || [ "$SCHLOCKER_GID" == "0" ] || [ "$SCHLOCKER_GROUP" == "root" ]; then
    echo
    echo "* * * ERROR: trying to run as root -- I cannot let you do that, Dave!"
    echo
    exit 1
fi

# get group data, if any, and check if the group exists
if GROUP_DATA=`getent group "$SCHLOCKER_GROUP"`; then
  # it does! do we have the gid given?
  if [[ "$SCHLOCKER_GID" != "" ]]; then
    # we do! do these match?
    if [[ `echo "$GROUP_DATA" | cut -d ':' -f 3` != "$SCHLOCKER_GID" ]]; then
      # they don't. we have a problem
      echo "ERROR: group $SCHLOCKER_GROUP already exists, but with a different gid (`echo "$GROUP_DATA" | cut -d ':' -f 3`) than provided ($SCHLOCKER_GID)!"
      exit 3
    fi
  fi
  # if no gid given, the existing group satisfies us regardless of the GID

# group does not exist
else
  # do we have the gid given?
  GID_ARGS=""
  if [[ "$SCHLOCKER_GID" != "" ]]; then
    # we do! does a group with a given id exist?
    if getent group "$SCHLOCKER_GID" >/dev/null; then
      echo "ERROR: a group with a given id ($SCHLOCKER_GID) already exists, can't create group $SCHLOCKER_GROUP with this id"
      exit 4
    fi
    # prepare the fragment of the groupadd command
    GID_ARGS="-g $SCHLOCKER_GID"
  fi
  # we either have no GID given (and don't care about it), or have a GID given that does not exist in the system
  # great! let's add the group
  groupadd $GID_ARGS "$SCHLOCKER_GROUP"
fi


# get user data, if any, and check if the user exists
if USER_DATA=`id -u "$SCHLOCKER_USER" 2>/dev/null`; then
  # it does! do we have the uid given?
  if [[ "$SCHLOCKER_UID" != "" ]]; then
    # we do! do these match?
    if [[ "$USER_DATA" != "$SCHLOCKER_UID" ]]; then
      # they don't. we have a problem
      echo "ERROR: user $SCHLOCKER_USER already exists, but with a different uid ("$USER_DATA") than provided ($SCHLOCKER_UID)!"
      exit 5
    fi
  fi
  # if no uid given, the existing user satisfies us regardless of the uid
  # but is he in the right group?
  adduser "$SCHLOCKER_USER" "$SCHLOCKER_GROUP"

# user does not exist
else
  # do we have the uid given?
  UID_ARGS=""
  if [[ "$SCHLOCKER_UID" != "" ]]; then
    # we do! does a group with a given id exist?
    if getent passwd "$SCHLOCKER_UID" >/dev/null; then
      echo "ERROR: a user with a given id ($SCHLOCKER_UID) already exists, can't create user $SCHLOCKER_USER with this id"
      exit 6
    fi
    # prepare the fragment of the useradd command
    UID_ARGS="-u $SCHLOCKER_UID"
  fi
  # we either have no UID given (and don't care about it), or have a UID given that does not exist in the system
  # great! let's add the user
  useradd $UID_ARGS -d "$SCHLOCKER_HOMEDIR" -r -g "$SCHLOCKER_GROUP" "$SCHLOCKER_USER"
fi


#
# directories and permissions
#

# if the homedir is not there, create
if [ ! -d "$SCHLOCKER_HOMEDIR" ]; then
    echo "    +-- homedir missing, creating it at: $SCHLOCKER_HOMEDIR"
    mkdir -p "$SCHLOCKER_HOMEDIR" || exit 1
fi
# make sure the perms are correct
chown -R "$SCHLOCKER_USER:$SCHLOCKER_GROUP" "$SCHLOCKER_HOMEDIR"

# if the maildir is not there, create
if [ ! -d "$SCHLOCKER_MAILDIR" ]; then
    echo "    +-- Maildir missing, creating it at: $SCHLOCKER_MAILDIR"
    mkdir -p "$SCHLOCKER_MAILDIR" || exit 1
fi
# make sure the perms are correct
chown -R "$SCHLOCKER_USER:$SCHLOCKER_GROUP" "$SCHLOCKER_MAILDIR"

# if the tempdir is not there, create
if [ ! -d "$SCHLOCKER_TMPDIR" ]; then
    echo "    +-- Maildir tempdir missing, creating it at: $SCHLOCKER_TMPDIR"
    mkdir -p "$SCHLOCKER_TMPDIR" || exit 1
fi
# make sure the perms are correct
chown -R "$SCHLOCKER_USER:$SCHLOCKER_GROUP" "$SCHLOCKER_TMPDIR"


#
# config
#

# do we need it? if the config file exists, just use that
if [ ! -e "$SCHLOCKER_CONFIG_PATH" ]; then
    echo "+-- no config file found in $SCHLOCKER_CONFIG_PATH, creating one..."

    # hopefully the unneeded settings will be ignored ;)
    SCHLOCKER_CONFIG="---
superadmin:  $SCHLOCKER_CONFIG_SUPERADMIN
lists_dir:   $SCHLOCKER_CONFIG_LISTS_DIR
keyword_handlers_dir: $SCHLOCKER_CONFIG_KEYWORD_HANDLERS_DIR
log_level:   $SCHLOCKER_CONFIG_LOG_LEVEL
smtp_settings:
    # For explanation see documentation for ActionMailer::smtp_settings, e.g. <http://api.rubyonrails.org/classes/ActionMailer/Base.html>.
    address: $SCHLOCKER_CONFIG_SMTP_HOST
    port: $SCHLOCKER_CONFIG_SMTP_PORT
    #domain:
    #enable_starttls_auto:
    #openssl_verify_mode:
    #authentication:
    #user_name:
    #password:
database:
    production:
        adapter:  $SCHLOCKER_DB_ADAPTER
        database: $SCHLOCKER_DB_DATABASE
        encoding: $SCHLOCKER_DB_ENCODING
        username: $SCHLOCKER_DB_USERNAME
        password: $SCHLOCKER_DB_PASSWORD
        host:     $SCHLOCKER_DB_HOST
api:
    host: 0.0.0.0
    port: 4443
    # Certificate and key to use. You can create new ones with 'schleuder cert generate'.
    tls_cert_file: /etc/schleuder/api-daemon.crt
    tls_key_file: /etc/schleuder/api-daemon.key
    # List of api_keys to allow access to the API.
    # Example:
    # valid_api_keys:
    #   - abcdef...
    #   - zyxwvu...
    valid_api_keys:
      - $SCHLOCKER_CONFIG_API_KEY
"
    mkdir -p "$( dirname "$SCHLOCKER_CONFIG_PATH" )"
    echo -e "$SCHLOCKER_CONFIG" > "$SCHLOCKER_CONFIG_PATH"

    # if the list directory is not there, create
    if [ ! -d "$SCHLOCKER_CONFIG_LISTS_DIR" ]; then
        echo "    +-- List data directory missing, creating it at: $SCHLOCKER_CONFIG_LISTS_DIR"
        mkdir -p "$SCHLOCKER_CONFIG_LISTS_DIR" || exit 1
    fi
    # make sure the perms are correct
    chown -R "$SCHLOCKER_USER:$SCHLOCKER_GROUP" "$SCHLOCKER_CONFIG_LISTS_DIR"
else
    echo "+-- config file found in '$SCHLOCKER_CONFIG_PATH', ignoring \$SCHLOCKER_CONFIG_* and \$SCHLOCKER_DB_* envvars"
fi

#
# we need a properly set-up database
#

# do we have a database?
echo "+-- testing if db is set-up properly..."
# run schleuder-api-daemon for a short while
su -p -c "env PATH=\"$PATH\" schleuder-api-daemon" "$SCHLOCKER_USER" &
export SCHLEUDER_PID=$!
sleep 5 && kill "$SCHLEUDER_PID" &
if ! wait $SCHLEUDER_PID; then
    echo "+-- setting up schleuder-api-daemon database..."
    echo y | schleuder install
    chown -R "$SCHLOCKER_USER:$SCHLOCKER_GROUP" /etc/schleuder
    # if we're using sqlite, we need to make sure the db file has the right permissions
    # but *only* when config file had to be created!
    if [ ! -z ${SCHLOCKER_CONFIG+x} ] && [ "$SCHLOCKER_DB_ADAPTER" == "sqlite3" ]; then
        echo "+-- config had to be created and we're using sqlite3 -- handling database file permissions..."
        chown -R "$SCHLOCKER_USER:$SCHLOCKER_GROUP" "$SCHLOCKER_DB_DATABASE"
    fi
fi

#
# start the watch
if [ "$SCHLOCKER_MAILDIR" != "" ]; then
    echo "+-- \$SCHLOCKER_MAILDIR is not empty, setting up watches"
    watch_maildir &
    sleep 1
fi

echo -e "\n\n"
echo "Note the following fingerprint and use it in the client-applications (schleuder-cli, schleuder-web, ...)."
schleuder cert fingerprint
echo -e "\n\n"

#
# run schleuder-api-daemon!
export SCHLOCKER_USER
echo "+-- starting command: $*..."
# cannot use exec here... fails at key generation
su -c "PATH=\"$PATH\" BUNDLE_PATH=\"$BUNDLE_PATH\" $*" "$SCHLOCKER_USER"
