# govers: is a set of functions intended to be sourced in your environment and provides go version management
#         based in a large part on:  https://icanhazdowntime.org/posts/2019-10-11-go-has-a-built-in-go-version-manager/
#         and with additional from:  https://github.com/moovweb/gvm/blob/master/scripts/listall

# colors
cEnd='\033[0m'
cCyan='\033[36m'
cCyanBold='\033[1;36m'
cGreenBold='\033[1;32m'
cRedBold='\033[1;91m'
cYellowBold='\033[1;33m'

if [ -z "${GOVERS_INSTALL_DIR}" ]; then
  GOVERS_INSTALL_DIR=$HOME/sdk
fi
mkdir -p ${GOVERS_INSTALL_DIR}

goversHelpText() {
  read -r -d '' helpText <<EOF || :
  ${cCyanBold}usage: govers use|list|remove|installed [-v] {goversion}${cEnd}
       ${cGreenBold}2nd arg | -v | --version${cEnd}:     ${cCyan}the Go version${cEnd}

    ${cCyanBold}example:${cEnd}
    ${cYellowBold}>${cEnd} govers use go1.15.2
    ${cYellowBold}>${cEnd} govers use -v 'go1.15.2'
    ${cYellowBold}>${cEnd} govers use --version 'go1.15.2'

  Installs to \$HOME/sdk by default.  Set \$GOVERS_INSTALL_DIR to override.
EOF

  echo -e "$helpText"
}

goversError() {
  msg="$1"
  echo -e "${cRedBold}${msg}${cEnd}"
  goversHelpText
  kill -INT $$
}

goversWrite() {
  local version="$1"

  # copied from: https://icanhazdowntime.org/posts/2019-10-11-go-has-a-built-in-go-version-manager/
  local groot="${GOVERS_INSTALL_DIR}/${version}"
  local gbd="${groot}/bin"
  if [ -d "${gbd}" ]; then
    # delete any go sdk path items
    local p="${gbd}:$(printf %s $PATH | awk -v RS=: -v ORS=: 'BEGIN { t="^'${GOVERS_INSTALL_DIR}'/go[0-9]\.[0-9]{1,2}(\.[0-9]{1,2}){1,2}/bin$" } $1!~t { print }')"

    # and set ENV VARs to this version's location
    local envFile="${GOVERS_INSTALL_DIR}/.env"
    echo "export PATH; PATH='${p}'" > "${envFile}"
    echo "export GOROOT; GOROOT='${groot}'" >> "${envFile}"
    echo "export GOMODCACHE; GOMODCACHE='"${GOVERS_INSTALL_DIR}/modcache"'" >> "${envFile}"
    echo "export GOTOOLDIR; GOTOOLDIR='"${groot}/pkg/tool/darwin_amd64"'" >> "${envFile}"

    # shellcheck source=${GOVERS_INSTALL_DIR}/.env
    . "${envFile}" &> /dev/null || goversError "Couldn't source environment"
  else
    goversError "unable to add ${gbd} to PATH because the directory doesn't exist"
  fi
}
goversGet() {
  local version="$1"

  if ! go install golang.org/dl/"${version}@latest" ; then
    goversError "failed to download ${version}"
  fi
  local cmd=("${version}" "download")
  "${cmd[@]}"
  # the command above unconditionally extracts to $HOME/sdk so we need to do some shuffling if
  # $GOVERS_INSTALL_DIR is not the default
  [ -d "${GOVERS_INSTALL_DIR}/${version}" ] || mv "${HOME}/sdk/${version}" "${GOVERS_INSTALL_DIR}"
}
goversSet() {
  local version="$1"

  local gbd="${GOVERS_INSTALL_DIR}/${version}/bin"
  if [ -d "${gbd}" ]; then
    goversWrite "${version}"
  else
    echo "${version} not found, installing with \"go get golang.org/dl/${version}; ${version} download\""
    goversGet "${version}"
    goversWrite "${version}"
  fi
  go version
}
goversListInstalled() {
  find "${GOVERS_INSTALL_DIR}" -maxdepth 1 -name 'go*' -type d | awk -F/ '/.*go.*$/{ print $NF }'
}
goversListVersions() {
  git ls-remote -t https://github.com/golang/go | awk -F/ '/.*go.*$/{ print $NF }' | less
}
goversRemove() {
  local version="$1"
  local verPath="${GOVERS_INSTALL_DIR}/${version}"

  if [ -d "$verPath" ]; then
    echo -e "${cCyan}Will now remove:${cEnd} ${cYellowBold}${verPath}${cEnd}"
    rm -rf "${verPath}"
  else
    echo -e "${cRedBold}Version path not found:${cEnd} ${cYellowBold}${verPath}${cEnd}"
  fi
}

goversArgs() {
  # argument parser nabbed from: https://stackoverflow.com/a/14203146/2712547
  POSITIONAL=()
  while [[ $# -gt 0 ]]
  do
  key="$1"

  case $key in
      -v|--version)
      version="$2"
      shift # past argument
      shift # past value
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
  done
  set -- "${POSITIONAL[@]}" # restore positional parameters
}

goversForceVersion() {
  if [ -z "$1" ]; then
    goversError 'version [$2 | -v | --version] argument is required'
  fi
}

govers() {
  goversArgs "$@"
  # now that args are processed, set our subcommand
  if (($# < 1)); then
    goversError "no subcommand supplied"
  fi

  local sub="$1"
  local version
  # populate version with positional 2nd arg if not already set from switches
  if [ -z "${version}" ]; then
    version="$2"
  fi

  # now perform the specified sub command
  case $sub in
      use)
        goversForceVersion "${version}"
        goversSet "${version}"
        ;;
      list)
        goversListVersions
        ;;
      installed)
        goversListInstalled
        ;;
      remove)
        goversForceVersion "${version}"
        goversRemove "${version}"
        ;;
      help)
        goversHelpText
        ;;
      *)
        goversError "unknown subcommand: '${sub}'"
        ;;
  esac
}
