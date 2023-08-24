#!/bin/bash

set -x

# Run tests for cros-codecs using ccdec and fluster.

# Arguments:
# $1: Architecture (amd/intel)
# $2: cros-codecs github action run id

FLUSTER_DIR="/opt/fluster"
ARCH="${1}"
CCDEC_BUILD_ID="${2}"
SINGLE_RUN="${3:-no}"

SUPPORTED_CODECS_intel="
    vp8 \
    vp9 \
    h.264 \
    h.265 \
"

SUPPORTED_CODECS_amd="
    vp9 \
    h.264 \
    h.265 \
"

TEST_SUITES_vp8="VP8-TEST-VECTORS"
TEST_SUITES_vp9="VP9-TEST-VECTORS"
TEST_SUITES_h264="JVT-AVC_V1"
TEST_SUITES_h265="JCT-VC-HEVC_V1"

#SKIP_VECTORS_amd_vp9_test_vectors="vp90-2-22-svc_1280x720_3.ivf vp91-2-04-yuv422.webm vp91-2-04-yuv444.webm"
#SKIP_VECTORS_amd_jvt_avc_v1="CVFC1_Sony_C FM1_BT_B FM1_FT_E FM2_SVA_C MR5_TANDBERG_C MR8_BT_B MR9_BT_B SP1_BT_A sp2_bt_b"
#SKIP_VECTORS_amd_jct_vc_hevc_v1="CONFWIN_A_Sony_1 PICSIZE_A_Bossen_1 PICSIZE_B_Bossen_1 RAP_B_Bossen_2 RPS_C_ericsson_5 RPS_E_qualcomm_5 TSUNEQBD_A_MAIN10_Technicolor_2"

SKIP_VECTORS_intel_vp8_test_vectors=""
SKIP_VECTORS_intel_vp9_test_vectors="vp90-2-22-svc_1280x720_3.ivf vp91-2-04-yuv422.webm vp91-2-04-yuv444.webm"
SKIP_VECTORS_intel_jvt_avc_v1="CVFC1_Sony_C FM1_BT_B FM1_FT_E FM2_SVA_C MR5_TANDBERG_C MR8_BT_B MR9_BT_B SP1_BT_A sp2_bt_b"
SKIP_VECTORS_intel_jct_vc_hevc_v1="CONFWIN_A_Sony_1 PICSIZE_A_Bossen_1 PICSIZE_B_Bossen_1 RAP_B_Bossen_2 RPS_C_ericsson_5 RPS_E_qualcomm_5 TSUNEQBD_A_MAIN10_Technicolor_2"

#if [ $ARCH == "amd" ]; then
#	echo "<LAVA_SIGNAL_TESTCASE TEST_CASE_ID=amd RESULT=fail>"
#	exit 0
#fi

CCDEC_URL="https://somewhere.google.com/cros-codecs/build/${CCDEC_BUILD_ID}/ccdec"
OLD_CCDEC_URL="https://people.collabora.com/~detlev/cros-codecs-tests/ccdec"

if [ ! -e /opt/cros-codecs/ccdec ]; then
	mkdir /opt/cros-codecs
	cd /opt/cros-codecs

	wget $CCDEC_URL || wget ${OLD_CCDEC_URL}
	chmod a+x ccdec
fi

export PATH=$PATH:/opt/cros-codecs

if [ "${SINGLE_RUN}" == "yes" ]; then
	FLUSTER_ARGS="-j 1"
fi

codecs_var_name="SUPPORTED_CODECS_${ARCH}"
eval "codecs=\$$codecs_var_name"

for codec in ${codecs}; do
	suite_var_name="TEST_SUITES_${codec/./}"
	eval "suites=\$$suite_var_name"
	for ts in ${suites}; do
		ts_lc=${ts,,}
		skip_var_name="SKIP_VECTORS_${ARCH}_${ts_lc//-/_}"
		eval "skip=\$$skip_var_name"
		if [ "${skip}" != "" ]; then
			SKIP_ARG="-sv ${skip}"
		fi
		echo Running /usr/bin/fluster_parser.py -ts ${ts} -d ccdec-${codec} ${SKIP_ARG} ${FLUSTER_ARGS}
		/usr/bin/fluster_parser.py -ts ${ts} -d ccdec-${codec} -t 300 ${SKIP_ARG} ${FLUSTER_ARGS}
		rm -f results.xml
	done
done

