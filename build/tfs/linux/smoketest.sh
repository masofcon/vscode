#!/bin/bash
set -e

. ./build/tfs/common/node.sh
. ./scripts/env.sh
. ./build/tfs/common/common.sh

export ARCH="x64"
export VSCODE_MIXIN_PASSWORD="$1"
VSO_PAT="$2"

echo "machine monacotools.visualstudio.com password $VSO_PAT" > ~/.netrc

export SCREENSHOTS="$AGENT_BUILDDIRECTORY/smoketest-screenshots"
export LOGS="$AGENT_BUILDDIRECTORY/smoketest-logs"

function configureEnvironment {
	id -u testuser &>/dev/null || (useradd -m testuser; chpasswd <<< testuser:testpassword)
	sudo -i -u testuser -- sh -c 'git config --global user.name "VS Code Agent" &&  git config --global user.email "monacotools@microsoft.com"'

	sudo rm -rf $SCREENSHOTS
	mkdir -p $SCREENSHOTS
	chown -R testuser $SCREENSHOTS

	sudo rm -rf $LOGS
	mkdir -p $LOGS
	chown -R testuser $LOGS
}

function runSmokeTest {
	DISPLAY=:10 sudo -i -u testuser -- sh -c "cd $BUILD_SOURCESDIRECTORY/test/smoke && ./node_modules/.bin/mocha --build $AGENT_BUILDDIRECTORY/VSCode-linux-x64 --screenshots $SCREENSHOTS --logs $LOGS"
}

step "Install dependencies" \
	npm install --arch=$ARCH --unsafe-perm

step "Mix in repository from vscode-distro" \
	npm run gulp -- mixin

step "Get Electron" \
	npm run gulp -- "electron-$ARCH"

step "Install distro dependencies" \
	node build/tfs/common/installDistro.js --arch=$ARCH

step "Build minified" \
	npm run gulp -- "vscode-linux-$ARCH-min"

step "Configure environment" \
	configureEnvironment

step "Run smoke test" \
	runSmokeTest

