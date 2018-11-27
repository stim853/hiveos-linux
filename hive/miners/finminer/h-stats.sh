#!/usr/bin/env bash

#######################
# MAIN script body
#######################

. /hive/custom/finminer/h-manifest.conf

stats_raw=`echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | nc -w $API_TIMEOUT localhost $MINER_API_PORT | jq '.result'`
if [[ $? -ne 0  || -z $stats_raw ]]; then
	echo -e "${YELLOW}Failed to read $miner stats_raw from localhost:${MINER_API_PORT}${NOCOLOR}"
else
	khs=`echo $stats_raw | jq -r '.[2]' | awk -F';' '{print $1}'`
	local tempfans=`echo $stats_raw | jq -r '.[6]' | tr ';' ' '`
	local temp=()
	local fan=()
	local tfcounter=0
	for tf in $tempfans; do
		(( $tfcounter % 2 == 0 )) &&
			temp+=($tf) ||
			fan+=($tf)
		((tfcounter++))
	done
	temp=`printf '%s\n' "${temp[@]}" | jq --raw-input . | jq --slurp -c .`
	fan=`printf '%s\n' "${fan[@]}" | jq --raw-input . | jq --slurp -c .`

	local hs=`echo "$stats_raw" | jq -r '.[3]' | tr ';' '\n' | jq -cs '.'`

	local ac=`echo $stats_raw | jq -r '.[2]' | awk -F';' '{print $2}'`
	local rj=`echo $stats_raw | jq -r '.[2]' | awk -F';' '{print $3}'`
	local ver=`echo $stats_raw | jq -r '.[0]' | awk '{print $1}'`

	[[ ! -z $FINMINER_ALGO ]] && local algo=$FINMINER_ALGO || local algo="ethash"

	stats=$(jq -n \
		--arg uptime "`echo \"$stats_raw\" | jq -r '.[1]' | awk '{print $1*60}'`" \
		--argjson hs "$hs" --argjson temp "$temp" --argjson fan "$fan" \
		--arg ac "$ac" --arg rj "$rj" \
		--arg algo "$algo" --arg ver "$ver" \
		'{$hs, $temp, $fan, $uptime, $algo, ar: [$ac, $rj], $ver}')
fi

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"