#!/usr/bin/env bash
# $gitdir: Directory containing git repo
# $gitbranch: Branch we are going to install the DB
# $npmcmd: Path to the npm executable (global)
# $npmbase: Base directory where we'll store multiple npm packages versions (subdirectories per branch)
# $nodecmd: Optional, path to the node executable (global)
# $shifterversion: Optional, defaults to 0.4.6. Not installed if there is a package.json file (present in 29 and up)
# $recessversion: Optional, defaults to 1.1.9 (Important! it's the only legacy version working. Older ones
#    lead to empty results). Not installed if there is a package.json file (present in 29 and up)

# Let's be strict. Any problem leads to failure.
set -e

required="gitdir gitbranch npmcmd npmbase"
for var in $required; do
    if [ -z "${!var}" ]; then
        echo "ERROR: ${var} environment variable is not defined. See the script comments."
        exit 1
    fi
done

# calculate some variables
mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Apply some defaults.
shifterversion=${shifterversion:-0.4.6}
recessversion=${recessversion:-1.1.9}

# Print nodejs and npm versions for informative purposes
if [[ -x ${nodecmd} ]]; then
    echo "INFO: node version: $(${nodecmd} --version)"
fi
if [[ -x ${npmcmd} ]]; then
    echo "INFO: npm  version: $(${npmcmd} --version)"
fi

# Move to base directory
cd ${gitdir}

# Verify we have the npmbase dir, creating if needed
if [[ ! -d ${npmbase} ]]; then
    echo "WARN: npmbase dir (${npmbase}) not found. Creating it"
    mkdir -p ${npmbase}
    echo "INFO: npmbase dir (${npmbase}) created"
else
    echo "OK: npmbase dir (${npmbase}) found"
fi

# Verify we have already the gitbranch dir, creating if needed
if [[ ! -d ${npmbase}/${gitbranch}/node_modules ]]; then
    echo "WARN: npmbase for branch (${gitbranch}) not found. Creating it"
    mkdir -p ${npmbase}/${gitbranch}/node_modules
    echo "INFO: npmbase for branch (${gitbranch}) created"
else
    echo "OK: npmbase for branch (${gitbranch}) found"
fi

# Install general stuff only if there is a package.json file
if [[ -f ${gitdir}/package.json ]]; then

    # Linking it (after removing, just in case)
    echo "INFO: Linking ${npmbase}/${gitbranch}/node_modules to ${gitdir}/node_modules"
    ln -nfs ${npmbase}/${gitbranch}/node_modules ${gitdir}/node_modules

    echo "INFO: Installing npm stuff following package/shrinkwrap details"

    # Always run npm install to keep our npm packages correct
    ${npmcmd} --no-color install

    # Verify there is a grunt executable available, installing if missing
    gruntcmd="$(${npmcmd} bin)"/grunt
    if [[ ! -f ${gruntcmd} ]]; then
        echo "WARN: grunt-cli executable not found. Installing everything"
        ${npmcmd} install --no-color grunt-cli
    fi
else

    cd ${npmbase}/${gitbranch}

    # Install shifter version if there is not package.json
    # (this is required for branches < 29_STABLE)
    shifterinstall=""
    shiftercmd="$(${npmcmd} bin)"/shifter
    if [[ ! -f ${shiftercmd} ]]; then
        echo "WARN: shifter executable not found. Installing it"
        shifterinstall=1
    else
        # Have shifter, look its version matches expected one
        # Cannot use --version because it's varying (performing calls to verify latest). Use --help instead
        shiftercurrent=$(${shiftercmd} --no-color --help | head -1 | cut -d "@" -f2)
        if [[ "${shiftercurrent}" != "${shifterversion}" ]]; then
            echo "WARN: shifter executable "${shiftercurrent}" found, "${shifterversion}" expected. Installing it"
            shifterinstall=1
        else
            # All right, shifter found and version matches
            echo "INFO: shifter executable (${shifterversion}) found"
        fi
    fi
    if [[ -n ${shifterinstall} ]]; then
        ${npmcmd} --no-color install shifter@${shifterversion}
        echo "INFO: shifter executable (${shifterversion}) installed"
    fi

    # Install recess version if there is not package.json
    # (this is required for branches < 29_STABLE)
    recessinstall=""
    recesscmd="$(${npmcmd} bin)"/recess
    if [[ ! -f ${recesscmd} ]]; then
        echo "WARN: recess executable not found. Installing it"
        recessinstall=1
    else
        # Have recess, look its version matches expected one
        recesscurrent=$(${recesscmd} --no-color --version)
        if [[ "${recesscurrent}" != "${recessversion}" ]]; then
            echo "WARN: recess executable "${recesscurrent}" found, "${recessversion}" expected. Installing it"
            recessinstall=1
        else
            # All right, recess found and version matches
            echo "INFO: recess executable (${recessversion}) found"
        fi
    fi
    if [[ -n ${recessinstall} ]]; then
        ${npmcmd} --no-color install recess@${recessversion}
        echo "INFO: recess executable (${recessversion}) installed"
    fi
fi

# Move back to base directory.
cd ${gitdir}

# Output information about installed binaries.
echo "INFO: Installation ended"
echo "INFO: Available binaries @ ${gitdir}"
echo "INFO: (Contents of $(${npmcmd} bin))"
for binary in $(ls $(${npmcmd} bin)); do
    echo "INFO:    - Installed ${binary}"
done
