#!/bin/bash
#**************************************************************************
#
# Author : Sumeet R Pawnikar  <sumeet.r.pawnikar@intel.com>
# Copyright 2016-2021 Chrome PnP - Intel Corporation
# All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sub license, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice (including the
# next paragraph) shall be included in all copies or substantial portions
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
#**************************************************************************
log_file="/home/`date +"%Y%m%d_%H%M%S"`_thrm_log.csv"

echo -e "\n \e[1;33m This Thermal debug script supports Alder Lake SoC: "

#max_no_of_cores=$((`cat /proc/cpuinfo | grep -i "processor" | tail -1 | cut -f2 -d ":" | tr -d ' ' | tr -d '[[:space:]]'`+1))
NUM_CPUS=`lscpu | grep "CPU(s):"|awk '{print $2}'`

for ((i=0;i<$NUM_CPUS;i++))
do
    var[$i]="CPU"$i","
done

thermal=$(cat /sys/class/thermal/thermal_zone*/type | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}')
temps_info=$(ectool tempsinfo all | awk '{print $3}' | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}')
echo "Date",$thermal,PL1,PL2,PL4,mmio-PL1,mmio-pl2,${var[@]}GPU_cur_freq,GPU_boost_freq,GPU_act_freq,EPP,Scaling_Governor,IA_Perf_Limit,GT_Perf_Limit,Ring_Perf_Limit,HWP_Capability,HWP_Req_Pkg,HWP_Req_CPU,IA_perf_ctl,IA_perf_status,Pkg_Energy_status,PL3_control,VR_current_config_PL4,fan_rpm,TCHG_state,$temps_info,AC_DC_Status,Full_Charge,Remaining_Charge,Enabled_Slice_Mask,Enabled Slice Total,Enabled Subslice Total,Enabled EU Total,Enabled EU Per Subslice,RC_6_Residencies,RC_0_Residencies,Uptime>> $log_file

while true
fan_rpm=$(ectool pwmgetfanrpm | awk '{print $4}')
thermal_zone=$(cat /sys/class/thermal/thermal_zone*/temp | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}')
powerlimit=$(cat /sys/class/powercap/intel-rapl/intel-rapl\:0/constraint_*_power_limit_uw | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}')
mmio_powerlimit=$(cat /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio\:0/constraint_*_power_limit_uw | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}')
cpufreq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}')
gpufreq_cur=$(cat /sys/class/drm/card0/gt_cur_freq_mhz)
gpufreq_boost=$(cat /sys/class/drm/card0/gt_boost_freq_mhz)
gpufreq_act=$(cat /sys/class/drm/card0/gt_act_freq_mhz)
EPP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)
Gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
IA_PL=$(iotools rdmsr 0 0x64f)
GT_PL=$(iotools rdmsr 0  0x6B0)
Ring_PL=$(iotools rdmsr 0  0x6B1)
HWP_Capability=$(iotools rdmsr 0  0x771)
HWP_Request_Pkg=$(iotools rdmsr 0  0x772)
HWP_Request_CPU=$(iotools rdmsr 0  0x774)
IA_perf_ctl=$(iotools rdmsr 0  0x199)
IA_perf_status=$(iotools rdmsr 0  0x198)
Pkg_Energy_status=$(iotools rdmsr 0  0x611)
PL3_control=$(iotools rdmsr 0  0x615)
VR_current_config_PL4=$(iotools rdmsr 0  0x601)
temps=$(ectool temps all | grep "C" | awk '{print (($2-273.15)*1000)}' | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}')
TCHG_state=$(cat /sys/class/thermal/cooling_device4/cur_state)
ac_dc_status=$(ectool battery | grep Flags | awk '{print $3}')
full_charge=$(ectool battery | grep "Last full charge" | awk '{print $4}')
remaining_charge=$(ectool battery | grep "Remaining capacity" | awk '{print $3}')
enabled_slice_mask=$(cat /sys/kernel/debug/dri/0/i915_sseu_status | grep "Enabled Slice Mask" | awk '{print $4}')
enabled_slice_total=$(cat /sys/kernel/debug/dri/0/i915_sseu_status | grep "Enabled Slice Total" | awk '{print $4}')
enabled_subslice_total=$(cat /sys/kernel/debug/dri/0/i915_sseu_status | grep "Enabled Subslice Total" | awk '{print $4}')
enabled_eu_total=$(cat /sys/kernel/debug/dri/0/i915_sseu_status | grep "Enabled EU Total" | awk '{print $4}')
enabled_eu_per_subslice=$(cat /sys/kernel/debug/dri/0/i915_sseu_status | grep "Enabled EU Per Subslice" | awk '{print $5}')
rc6_one=$(cat /sys/class/drm/card0/power/rc6_residency_ms)
sleep 1
rc6_two=$(cat /sys/class/drm/card0/power/rc6_residency_ms)
rc6=$[(rc6_two - rc6_one)/10]
rc0=$(echo "scale=2; 100 - $rc6" | bc)
uptime=`uptime`

do
#echo `date +"%Y%m%d-%H%M%S"` ,$thermal_zone,$powerlimit,$cpufreq,$gpufreq,$EPP,$Gov,$IA_PL,$GT_PL,$Ring_PL,$HWP_Capability,$HWP_Request_Pkg,$HWP_Request_CPU,$fan_rpm,$TCHG_state,$temps,$uptime>> $log_file
#echo `date +"%Y%m%d-%H%M%S"` ,$thermal_zone,$powerlimit,$cpufreq,$gpufreq,$EPP,$Gov,$IA_PL,$GT_PL,$Ring_PL,$HWP_Capability,$HWP_Request_Pkg,$HWP_Request_CPU,$fan_rpm,$TCHG_state,$temps,$ac_dc_status,$full_charge,$remaining_charge,$uptime>> $log_file
echo `date +"%Y%m%d-%H%M%S"` ,$thermal_zone,$powerlimit,$mmio_powerlimit,$cpufreq,$gpufreq_cur,$gpufreq_boost,$gpufreq_act,$EPP,$Gov,$IA_PL,$GT_PL,$Ring_PL,$HWP_Capability,$HWP_Request_Pkg,$HWP_Request_CPU,$IA_perf_ctl,$IA_perf_status,$Pkg_Energy_status,$PL3_control,$VR_current_config_PL4,$fan_rpm,$TCHG_state,$temps,$ac_dc_status,$full_charge,$remaining_charge,$enabled_slice_mask,$enabled_slice_total,$enabled_subslice_total,$enabled_eu_total,$enabled_eu_per_subslice,$rc6,$rc0,$uptime>> $log_file
#echo `date +"%Y%m%d-%H%M%S"` ,$cpufreq,$gpufreq_cur,$gpufreq_act
#echo `date +"%Y%m%d-%H%M%S"` ,$thermal_zone,$powerlimit,$cpufreq,$gpufreq,$EPP,$Gov,$IA_PL,$GT_PL,$Ring_PL,$HWP_Capability,$HWP_Request_Pkg,$HWP_Request_CPU,$fan_rpm,$TCHG_state,$temps,$uptime>> $log_file
sleep 1s
done
