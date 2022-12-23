#!/usr/bin/env sh

color() {
	codes=
	if [ "$1" = 'bold' ]; then
		codes='1'
		shift
	fi
	if [ "$#" -gt 0 ]; then
		code=
		case "$1" in
			# see https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
			black) code=30 ;;
			red) code=31 ;;
			green) code=32 ;;
			yellow) code=33 ;;
			blue) code=34 ;;
			magenta) code=35 ;;
			cyan) code=36 ;;
			white) code=37 ;;
		esac
		if [ "$code" ]; then
			codes="${codes:+$codes;}$code"
		fi
	fi
	printf '\033[%sm' "$codes"
}
wrap_color() {
	text="$1"
	shift
	color "$@"
	printf '%s' "$text"
	color reset
	echo
}

wrap_good() {
	echo "$(wrap_color "$1" white): $(wrap_color "$2" green)"
}
wrap_bad() {
	echo "$(wrap_color "$1" bold): $(wrap_color "$2" bold red)"
}
wrap_warning() {
	wrap_color >&2 "$*" red
}


echo 'Verify TDX Host Status:'

# Check the system initialization messages after system boot
tdx_module_init_command=$(dmesg | grep -i TDX | grep  'Successfully initialized TDX module' | wc -l)
if [ $tdx_module_init_command -eq 1 ]; then
	echo " - $(wrap_good "TDX module" 'enabled')"
else
	echo " - $(wrap_bad "TDX module" 'missing')"
fi


# Check /proc/cpuinfo attributes
proc_cpuinfo_command=$(grep -o tdx /proc/cpuinfo | grep tdx | wc -l)
if [ $proc_cpuinfo_command -ge 1 ]; then
	echo " - $(wrap_good "/proc/cpuinfo attributes" 'enabled')"
else
	echo " - $(wrap_bad "/proc/cpuinfo attributes" 'missing')"
fi

# Check MSR 0x1401 bit 11
MSR_command=$(rdmsr 0x1401 -f 11:11)
if [ $MSR_command -eq 1 ]; then
	echo " - $(wrap_good "MSR 0x1401 bit 11" 'enabled')"
else
	echo " - $(wrap_bad "MSR 0x1401 bit 11" 'missing')"
fi

# Check Number of TDX key
TDX_key_number_command=$(sudo rdmsr -f 63:32 0x87)
if [ $MSR_command -ge 1 ]; then
        echo " - $(wrap_good "Number of TDX key" 'enabled')"
else
        echo " - $(wrap_bad "Number of TDX key" 'missing')"
fi

echo 'Verify PCCS package and active:'
if [ $(systemctl is-active pccs) = "active" ]; then
	echo " - $(wrap_good "pccs is installed" 'enabled')"
	echo " - $(wrap_good "pccs is active" 'enabled')"
#	echo $(systemctl status pccs)
#	echo $(rpm -qa|grep sgx-dcap-pccs)
elif [ $(systemctl is-active pccs) = "inactive" ] && [ $(rpm -qa|grep sgx-dcap-pccs|wc -l) -ge 1 ]; then
	echo " - $(wrap_good "pccs is installed" 'enabled')"
	echo " - $(wrap_bad "pccs is active" 'missing')"
else
	echo " - $(wrap_bad "pccs is installed" 'missing')"
	echo " - $(wrap_bad "pccs is active" 'missing')"
fi

echo 'Verify QGS installed and active:'
if [ $(systemctl is-active qgsd) = "active" ]; then
        echo " - $(wrap_good "qgs is installed" 'enabled')"
        echo " - $(wrap_good "qgs is active" 'enabled')"
#       echo $(systemctl status pccs)
#       echo $(rpm -qa|grep sgx-dcap-pccs)
elif [ $(systemctl is-active qgsd) = "inactive" ] && [ $(rpm -qa|grep tdx-qgs|wc -l) -ge 1 ]; then
        echo " - $(wrap_good "qgs is installed" 'enabled')"
        echo " - $(wrap_bad "qgs is active" 'missing')"
else
        echo " - $(wrap_bad "qgs is installed" 'missing')"
        echo " - $(wrap_bad "qgs is active" 'missing')"
fi

echo 'Verify QPL installed:'
if [ $(rpm -qa|grep libsgx-dcap-default-qp|wc -l) -ge 1 ]; then
	echo " - $(wrap_good "qpl is installed" 'enabled')"
else
	echo " - $(wrap_bad "qpl is installed" 'missing')"
fi
