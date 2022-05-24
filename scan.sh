#/bin/sh
#author: gaoshang
#date: 2022/5/22

:<<! 
|----------------------------------------------------------------------------------|
|illustration: 																	   |
|	This tools is used for scanning the target machine\'s ip and port easier and   |
|quicker.It also can deal with the problem during scanning.						   |
|----------------------------------------------------------------------------------|

|----------------------------------------------------------------------------------|
|Note: 																			   |
|	1. 0 means 'NO' and 1 means 'YES'.											   |
|----------------------------------------------------------------------------------|
!

########################################################################
#========================>>constant parameter<<========================#
########################################################################

#color
readonly WHITE='\033[0;37m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly COLOR_OFF='\033[0m'

#basic parameter
readonly SEPARTOR='-----------'
readonly START='\e'
readonly END='\e[0m'

#the parameters of local machine
readonly LOCAL_IP=$(ifconfig|grep 'inet '|awk '{print $2}'|head -n 1)
readonly IS_ROOT=$(whoami)
#readonly 

#machines' message.The first index is 0
machines_array=()
#ports.The first index is 1
ports_array=()

#machines which open 21 port.The first index is 0
machines_21=()
#machines which open 22 port.The first index is 0
machines_22=()
#machines which open 80 port.The first index is 0
machines_80=()
#gobuster scan result.The first index is 0
gobuster_result=()

########################################################################
#============================>>functions<<=============================#
########################################################################
#print the info of parameter
print_parameter(){
	printf "$1 ${GREEN}$2${COLOR_OFF}\n"
}
#scan machine
scan_machine(){
	result=$(nmap ${LOCAL_IP}/24)
#	TODO It's very slow.
#	result=$(cat ./result.txt)
	machines=$(echo -e "${result}"|grep 'Nmap scan report for '|awk '{if ($6=="") print $5; else print $6;}'|egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
	machines_array=($machines)
	ports_tmp=$(echo -e "${result}"|egrep "^Nmap scan report for|^[0-9]*/")
	#echo -e "${ports_tmp}\n"
	index=0
	i=1
	port=''
	while true
	do 
		tmp_line=$(echo -e "${ports_tmp}"|sed -n "$i""p")
		if [ "$tmp_line" = "" ]; 
		then
			ports_array[index]=$port
			break; 
		fi
		if [ "$(echo -e "${tmp_line}"|grep "^Nmap")" ];
		then
			ports_array[index++]=$port
			port=''
		else
			port=$port"$(echo -e "${tmp_line}"|awk '{printf("%s%s%s/%s ","\033[0;31m",$1,"\033[0m",$3)}')"
		fi
		
		let "i++"
	done
	#echo "${ports[2]}"
	
}
#TODO scan the target machine's port.
scan_port(){
	printf "scan port"
}
#dirb scan
scan_gobuster(){
	for j in `seq ${#machines_80[@]}`
	do
		gobuster=""
		machine=${machines_80[j-1]}
		message=$(gobuster dir -u http://$machine/ -x html,txt,php -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt)
#		message=$(cat ./result1)
		pathes=$(echo -e "${message}"|egrep -o "/[a-zA-Z\.-]+\s+\([a-zA-Z:]+\s[0-9]+)")
		index=0
		i=1
		while true
		do 
			tmp=$(echo -e "${pathes}"|sed -n "$i""p")
			if [ "$tmp" == "" ] 
			then
				gobuster_result[index++]=$gobuster
				gobuster=""
				break
			else
				gobuster=$gobuster" $tmp\n"
			fi
			let "i++"
		done
	done
}
#ssh username and passwd scan
scan_ssh(){
	echo "to be continue..."
}
########################################################################
#=============================>>execute<<==============================#
########################################################################
#Get parameters
printf "*------------->${YELLOW}Getting the parameters${COLOR_OFF}<------------*\n"
printf "|%-49s|\n" "..."
printf "*------------------->${YELLOW}Parameters${COLOR_OFF}<-------------------*\n"
printf "|Local machine's ip is ${GREEN}%-27s${COLOR_OFF}|\n" ${LOCAL_IP}
printf "|Current user is ${GREEN}%-33s${COLOR_OFF}|\n" ${IS_ROOT}
printf "*-------------------------------------------------*\n\n\n\n"
printf "*------------>${YELLOW}Scanning hosts and ports${COLOR_OFF}<-----------*\n"
printf "|%-49s|\n" "..."
#nmap scan
scan_machine
printf "*------------------>${YELLOW}Hosts/Ports${COLOR_OFF}<------------------*\n"
for index1 in `seq ${#machines_array[@]}`
do
	printf "|${GREEN}%-49s${COLOR_OFF}|\n" ${machines_array[$index1-1]}	
	ports=(${ports_array[$index1]})
	if [ ${#ports[@]} -eq 0 ];
	then
		printf "|  ${RED}%-3s${COLOR_OFF}%-44s|\n" "-/-" "/-"
	fi
	for index2 in `seq ${#ports[@]}`
	do
		port=${ports[index2-1]}
		printf "|  %-58s|\n" ${port}
		
		num=$(echo "${port}"|egrep -o "[0-9]+"|sed -n "3p")
		case $num in 
			21)
				sum=${#machines_21[@]}
				machines_21[$sum]=${machines_array[$index1-1]}
				;;
			22)
				sum=${#machines_22[@]}
				machines_22[$sum]=${machines_array[$index1-1]}
				;;
			80)
				sum=${#machines_80[@]}
				machines_80[$sum]=${machines_array[$index1-1]}
				;;
			esac
	done
done
printf "*-------------------------------------------------*\n\n\n\n"
#dirb scan
printf "*------------->${YELLOW}Scanning the web path${COLOR_OFF}<-------------*\n"
printf "|%-49s|\n" "..."
printf "*------------------->${YELLOW}Web path${COLOR_OFF}<--------------------*\n"
scan_gobuster
for index1 in `seq ${#gobuster_result[@]}`
do
	if [ ${#gobuster_result[$index1-1]} -gt 0 ];
	then
		printf "|%-49s|\n" "${machines_80[index1-1]}"
		i=1
		while true
		do
			
			path=$(echo -e "${gobuster_result[$index1-1]}"|sed -n $i"p")
			if [ "$path" != "" ];
			then
				flag=$(echo $path|egrep -o "[0-9]+)$"|egrep -o "[0-9]+")
				case $flag in 
					200)
						printf "|  ${GREEN}%-47s${COLOR_OFF}|\n" "$path"
						;;
					302)
						printf "|  ${BLUE}%-47s${COLOR_OFF}|\n" "$path"
						;;
					*)
						printf "|  %-47s|\n" "$path"
						;;
				esac
			else
				break;
			fi
			let "i++"
		done
	fi
done
printf "*-------------------------------------------------*\n\n\n\n"

scan_ssh















