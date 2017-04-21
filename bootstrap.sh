#!/bin/bash
BASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_PATH="$BASE_PATH/.env"
DEPENDENCIES_FILE="$BASE_PATH/dependencies"
VIRTUALENV_GIT="https://github.com/pypa/virtualenv.git"
VIRTUALENV_PATH="$ENV_PATH/virtualenv"
VIRTUALENV="$VIRTUALENV_PATH/virtualenv.py"
NODE_BASE="$ENV_PATH/lib"
export GEM_HOME="$ENV_PATH/gems"
export GEM_PATH=""

function log() {
    echo $@
}

function env_install() {
    if [ ! -d $ENV_PATH ]; then
        log "Creatin the virtual environment..."
        mkdir -p "$ENV_PATH"
    fi
}

function python_base() {
    env_install
    if [ ! -d "$VIRTUALENV_PATH" ]; then
        log "Installing virtualenv"
        PYTHON=$(which python)
        GIT=$(which git)
        $GIT clone --depth 1 -q "$VIRTUALENV_GIT" "$VIRTUALENV_PATH"
        log "Executing virtualenv"
        $PYTHON "$VIRTUALENV" "$ENV_PATH"
    fi
}

function python_install() {
    python_base
    log "Installing python dependencies [$@]"
    for requirement in "$@"; do
        $ENV_PATH/bin/pip install -q $requirement
    done
}

function ruby_install() {
    mkdir -p "$GEM_HOME"
    log "Bootstraping ruby dependencies"
    for rubygem in "$@"; do
        gem install $rubygem --quiet
    done
}

function node_eval() {
    source $ENV_PATH/bin/activate
}

function node_install() {
    if [ ! -x $ENV_PATH/bin/node ]; then
        python_base
        log "Bootstrapping node"
        $ENV_PATH/bin/pip install -q nodeenv
        $ENV_PATH/bin/nodeenv -p
    fi
    source $ENV_PATH/bin/activate
    log "Bootstrapping node dependencies"
    for nodepkg in "$@"; do
        npm install ${nodepkg}@latest --loglevel silent --prefix $NODE_BASE
    done
}

function rclone_install() {
    python_base
    local RCLONE_FILE="$ENV_PATH/rclone/rclone-latest.zip"
    local RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-amd64.zip"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        RCLONE_URL="https://downloads.rclone.org/rclone-current-osx-amd64.zip"
    fi
    log "Installing httpie to download requirements"
    $ENV_PATH/bin/pip install -q --upgrade httpie
    $ENV_PATH/bin/pip install -q --upgrade requests[security]
    mkdir -p $ENV_PATH/rclone
    $ENV_PATH/bin/http --download --verify=no --output "$RCLONE_FILE" "$RCLONE_URL"
    $ENV_PATH/bin/python -m zipfile -e "$RCLONE_FILE" "$ENV_PATH/rclone"
    RCLONE_EXE="$(find "$ENV_PATH/rclone" -mindepth 1 -maxdepth 1 -type 'd')/rclone"
    log "RClone downloaded [$RCLONE_EXE]"
    mv "$RCLONE_EXE" $ENV_PATH/bin/rclone
    chmod +x "$ENV_PATH/bin/rclone"
}

function install_dependencies() {
    EXECUTABLE_NAME="$(basename $0)"
    DEPENDENCIES_LINE="$(grep "^${EXECUTABLE_NAME}:" "$DEPENDENCIES_FILE" | head -n 1)"
    FRAMEWORK="$(echo "$DEPENDENCIES_LINE" | cut -d ' ' -f 2)"
    if [ ! -f "$ENV_PATH/$EXECUTABLE_NAME.installed" ]; then
        FRAMEWORK_DEPENDENCIES="$(echo "$DEPENDENCIES_LINE" | cut -d ' ' -f 3-)"
        eval "${FRAMEWORK}_install $FRAMEWORK_DEPENDENCIES"
        touch "$ENV_PATH/$EXECUTABLE_NAME.installed"
    elif [ "$FRAMEWORK" == "node" ]; then
        node_eval
    fi
}

install_dependencies
