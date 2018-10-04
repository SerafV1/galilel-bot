#!@BASH@
#
# galilel-bot -- discord notification block for galilel coin daemon.
#
# Copyright (c) 2018 Maik Broemme <mbroemme@libmpq.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# load configuration file.
source "@SYSCONFDIR@/galilel/galilel-bot.conf"

# global variables with process information.
export GALILEL_BOT_PROCESS="$(@BASENAME@ "${0}")"
export GALILEL_BOT_VERSION="@GALILEL_BOT_VERSION@"
export GALILEL_BOT_AUTHOR="@GALILEL_BOT_AUTHOR@"

# global variables with sane defaults.
declare -g GLOBAL__parameter_debug="disabled"
declare -g GLOBAL__parameter_test="disabled"

# move config options to global variables.
declare -g GLOBAL__parameter_logfile="${LOGFILE:-/var/log/galilel/galilel-bot.log}"
declare -a GLOBAL__parameter_configs=("${COIN_CONFIGS[@]}")
declare -g GLOBAL__parameter_wallet_webhook_id="${DISCORD_WALLET_WEBHOOK_ID}"
declare -g GLOBAL__parameter_wallet_webhook_token="${DISCORD_WALLET_WEBHOOK_TOKEN}"
declare -g GLOBAL__parameter_block_webhook_id="${DISCORD_BLOCK_WEBHOOK_ID}"
declare -g GLOBAL__parameter_block_webhook_token="${DISCORD_BLOCK_WEBHOOK_TOKEN}"

# @_galilel_bot__printf()
#
# @_${1}: log level
# @_${2}: text string
#
# this function shows something on stdout and logs into a file.
function galilel_bot__printf() {

	# echo to logfile.
	case "${1}" in
		LOG_HELP)
			shift
		;;
		*)
			shift
			echo -e "$(@DATE@ '+%b %e %H:%M:%S')" "${HOSTNAME}" "${GALILEL_BOT_PROCESS}[$$]:" "${FUNCNAME[1]##*__}() ${@}" >> "${GLOBAL__parameter_logfile}"
		;;
	esac

	# echo to stdout.
	case "${GLOBAL__parameter_debug}" in
		enabled)
			echo -e "${FUNCNAME[1]##*__}() ${@}"
		;;
		disabled)
			echo -e "${@}"
		;;
	esac

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__show_help()
#
# this function shows the command line help.
function galilel_bot__show_help() {

	# show the help.
	galilel_bot__printf LOG_HELP "Usage: ${GALILEL_BOT_PROCESS} [OPTION]..."
	galilel_bot__printf LOG_HELP "${GALILEL_BOT_PROCESS} - send wallet and block notifications to discord."
	galilel_bot__printf LOG_HELP ""
	galilel_bot__printf LOG_HELP "Common arguments:"
	galilel_bot__printf LOG_HELP ""
	galilel_bot__printf LOG_HELP "  -h, --help            shows this help screen"
	galilel_bot__printf LOG_HELP "  -v, --version         shows the version information"
	galilel_bot__printf LOG_HELP "      --debug           shows debug information"
	galilel_bot__printf LOG_HELP "      --test            shows notification on console rather than in discord"
	galilel_bot__printf LOG_HELP ""
	galilel_bot__printf LOG_HELP "Notification arguments:"
	galilel_bot__printf LOG_HELP ""
	galilel_bot__printf LOG_HELP "      --notify-wallet   <ticker> <transaction id>"
	galilel_bot__printf LOG_HELP "                        discord notification about new transaction for address"
	galilel_bot__printf LOG_HELP "      --notify-block    <ticker> <blockhash>"
	galilel_bot__printf LOG_HELP "                        discord notification about new block on the network"
	galilel_bot__printf LOG_HELP ""
	galilel_bot__printf LOG_HELP "Please report bugs to the appropriate authors, which can be found in the"
	galilel_bot__printf LOG_HELP "version information."

	# if no error was found, return with successful status.
	return 2
}

# @_galilel_bot__get_switches()
#
# this function shows the command line version.
function galilel_bot__show_version() {

	# show the main script version.
	galilel_bot__printf LOG_HELP "${GALILEL_BOT_PROCESS} ${GALILEL_BOT_VERSION} ${GALILEL_BOT_RELEASE}"
	galilel_bot__printf LOG_HELP "Written by ${GALILEL_BOT_AUTHOR}"
	galilel_bot__printf LOG_HELP ""
	galilel_bot__printf LOG_HELP "This is free software; see the source for copying conditions. There is NO"
	galilel_bot__printf LOG_HELP "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."

	# if no error was found, return with successful status.
	return 2
}

# @_galilel_bot__notification_wallet()
#
# @_${1}: coin ticker
# @_${2}: transaction id
#
# this function sends message to discord on monitored wallet address changes.
function galilel_bot__notification_wallet() {

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__notification_block()
#
# @_${1}: coin ticker
# @_${2}: blockhash
#
# this function sends message to discord on block changes in the network.
function galilel_bot__notification_block() {

	# local variables.
	local LOCAL__ticker="${1}"
	local LOCAL__blockhash="${2}"

	# loop through the configuration array.
	local LOCAL__index
	for (( LOCAL__index = 0; LOCAL__index < "${#GLOBAL__parameter_configs[@]}" ; LOCAL__index++ )) ; do

		# read data into variables.
		IFS=':' read LOCAL__ticker LOCAL__username LOCAL__password LOCAL__ip LOCAL__port LOCAL__address <<< "${GLOBAL__parameter_configs[${LOCAL__index}]}"

		# fetch block information.
		@CURL@ \
			--request POST \
			--max-time 5 \
			--silent \
			--fail \
			--header 'content-type: text/plain;' \
			--data-binary '{ "jsonrpc" : "1.0", "id" : "curltest", "method" : "getblock", "params" : [ '"${LOCAL__blockhash}"' ] }' \
			--user "${LOCAL__username}:${LOCAL__password}" \
			"http://${LOCAL__ip}:${LOCAL__port}/" |
		while read LOCAL__line ; do

			# get block information.
			local LOCAL__height="$(@JSHON@ -Q -e result -e height -u <<< "${LOCAL__line}")"
			local LOCAL__difficulty="$(@JSHON@ -Q -e result -e difficulty -u <<< "${LOCAL__line}")"
			local LOCAL__time="$(@JSHON@ -Q -e result -e time -u <<< "${LOCAL__line}")"

			# get current date.
			local LOCAL__date="$(@DATE@ --date "@${LOCAL__time}")"

			# format variables.
			local LOCAL__difficulty="$(printf "%.2f" "${LOCAL__difficulty}")"

			# check if in test mode.
			[ "${GLOBAL__parameter_test}" == "enabled" ] && {
				galilel_bot__printf LOG_INFO "New block **'"${LOCAL__height}"'** at **'"${LOCAL__date}"'** with difficulty **'"${LOCAL__difficulty}"'**"
			}

			# check if in production mode.
			[ "${GLOBAL__parameter_test}" == "disabled" ] && {
				galilel_bot__printf LOG_ONLY "New block **'"${LOCAL__height}"'** at **'"${LOCAL__date}"'** with difficulty **'"${LOCAL__difficulty}"'**"

				# push block notification to discord.
				/usr/bin/curl \
					--request POST \
					--max-time 5 \
					--silent \
					--fail \
					--header 'content-Type: application/json' \
					--data-binary '{ "content" : "New block **'"${LOCAL__height}"'** at **'"$(/usr/bin/date --date "@${LOCAL__time}")"'** with difficulty **'"$(printf "%.2f" "${LOCAL__difficulty}")"'**" }' \
					"https://discordapp.com/api/webhooks/${GLOBAL__parameter_block_webhook_id}/${GLOBAL__parameter_block_webhook_token}"
			}
		done

		# check pipe status of curl command.
		case "${PIPESTATUS[0]}" in
			7)

				# connection error.
				galilel_bot__printf LOG_INFO "${GALILEL_BOT_PROCESS}: failed to connect to galilel RPC wallet"

				# return error.
				return 7
		esac
	done

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__init()
#
# this function initializes the application and does various permission checks.
function galilel_bot__init() {

	# check if logfile is writable.
	[ ! -w "${GLOBAL__parameter_logfile}" ] && {
		galilel_bot__printf LOG_HELP "${GALILEL_BOT_PROCESS}: logfile ${GLOBAL__parameter_logfile} is not writable"

		# return with error.
		return 1
	}

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__get_switches()
#
# this function parse the switches of the command line.
function galilel_bot__get_switches() {

	# first check if no parameter was given.
	[ "${#}" == "0" ] && {
		galilel_bot__printf LOG_HELP "${GALILEL_BOT_PROCESS}: no option given"
		galilel_bot__printf LOG_HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

		# return if we found nothing.
		return 1
	}

	# first parse command line for switches for help and version.
	for LOOP__argument in "${@}" ; do
		case "${LOOP__argument}" in
			-h|--help)
				galilel_bot__show_help || return "${?}"
			;;      
			-v|--version)
				galilel_bot__show_version || return "${?}"
			;;
			*)
				continue
			;;
		esac
	done

	# second parse command line for flags.
	for LOOP__argument in "${@}" ; do
		case "${LOOP__argument}" in
			--debug)
				declare -g GLOBAL__parameter_debug="enabled"
				shift
			;;
			--test)
				declare -g GLOBAL__parameter_test="enabled"
				shift
			;;
			*)
				continue
			;;
		esac
	done

	# third parse command line for main switches.
	while [ "${#}" -gt "0" ] ; do
		case "${1}" in
			--notify-wallet)

				# check if we miss some parameter.
				[ -z "${3}" ] && {

					# show the help for the missing parameter.
					galilel_bot__printf LOG_HELP "${GALILEL_BOT_PROCESS}: option \`${1}' requires 2 arguments"
					galilel_bot__printf LOG_HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

					# return if we missed some parameter.
					return 1
				}

				# wallet notification.
				galilel_bot__notification_wallet "${2}" "${3}" || return "${?}"

				# clear variables.
				shift 3
			;;
			--notify-block)

				# check if we miss some parameter.
				[ -z "${3}" ] && {

					# show the help for the missing parameter.
					galilel_bot__printf LOG_HELP "${GALILEL_BOT_PROCESS}: option \`${1}' requires 2 arguments"
					galilel_bot__printf LOG_HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

					# return if we missed some parameter.
					return 1
				}

				# wallet notification.
				galilel_bot__notification_block "${2}" "${3}" || return "${?}"

				# clear variables.
				shift 3
			;;
			*)

				# show the help for an unknown option.
				galilel_bot__printf LOG_HELP "${GALILEL_BOT_PROCESS}: unrecognized option \`${1}'"
				galilel_bot__printf LOG_HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

				# return if we found some unknown option.
				return 1

				# clear variables.
				shift
			;;
		esac

		# skip to next parameter.
		shift
	done

	# if no error was found, return zero.
	return 0
}

# main() starts here.
{
	galilel_bot__init &&
	galilel_bot__get_switches "${@}"
}

# parse return code.
case "${?}" in
	1)

		# general error.
		exit 1
	;;
	2)

		# showed help or version.
		exit 0
	;;
	*)

		# unknown error.
		exit "${?}"
	;;
esac
