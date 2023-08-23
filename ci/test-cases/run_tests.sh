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

SKIP_VECTORS_amd_vp9_test_vectors="vp90-2-03-deltaq.webm vp90-2-05-resize.ivf vp90-2-16-intra-only.webm vp90-2-18-resize.ivf vp90-2-22-svc_1280x720_3.ivf vp91-2-04-yuv422.webm vp91-2-04-yuv444.webm"
SKIP_VECTORS_amd_jvt_avc_v1="CVFC1_Sony_C FM1_BT_B FM1_FT_E FM2_SVA_C MR3_TANDBERG_B  MR4_TANDBERG_C MR5_TANDBERG_C SP1_BT_A sp2_bt_b"
SKIP_VECTORS_amd_jct_vc_hevc_v1="\
	AMP_D_Hisilicon_3 \
	AMP_E_Hisilicon_3 \
	CAINIT_A_SHARP_4 \
	CAINIT_B_SHARP_4 \
	CIP_A_Panasonic_3 \
	CIP_C_Panasonic_2 \
	CONFWIN_A_Sony_1 \
	DBLK_A_MAIN10_VIXS_4 \
	DBLK_D_VIXS_2 \
	DBLK_E_VIXS_2 \
	DBLK_F_VIXS_2 \
	DBLK_G_VIXS_2 \
	DSLICE_A_HHI_5 \
	DSLICE_B_HHI_5 \
	DSLICE_C_HHI_5 \
	ENTP_B_Qualcomm_1 \
	LTRPSPS_A_Qualcomm_1 \
	MAXBINS_C_TI_5 \
	MERGE_A_TI_3 \
	MERGE_B_TI_3 \
	MERGE_C_TI_3 \
	MERGE_D_TI_3 \
	MERGE_E_TI_3 \
	MVDL1ZERO_A_docomo_4 \
	NoOutPrior_A_Qualcomm_1 \
	NoOutPrior_B_Qualcomm_1 \
	NUT_A_ericsson_5 \
	OPFLAG_A_Qualcomm_1 \
	OPFLAG_C_Qualcomm_1 \
	PICSIZE_A_Bossen_1 \
	PICSIZE_B_Bossen_1 \
	PICSIZE_C_Bossen_1 \
	PICSIZE_D_Bossen_1 \
	PMERGE_A_TI_3 \
	PMERGE_B_TI_3 \
	PMERGE_C_TI_3 \
	PMERGE_D_TI_3 \
	PMERGE_E_TI_3 \
	RAP_A_docomo_6 \
	RAP_B_Bossen_2 \
	RPLM_A_qualcomm_4 \
	RPLM_B_qualcomm_4 \
	RPS_A_docomo_5 \
	RPS_C_ericsson_5 \
	RPS_E_qualcomm_5 \
	RPS_F_docomo_2 \
	SAO_A_MediaTek_4 \
	SAO_B_MediaTek_5 \
	SAO_E_Canon_4 \
	SAO_F_Canon_3 \
	SAO_G_Canon_3 \
	SAODBLK_A_MainConcept_4 \
	SAODBLK_B_MainConcept_4 \
	SDH_A_Orange_4 \
	SLICES_A_Rovi_3 \
	SLIST_B_Sony_9 \
	SLIST_D_Sony_9 \
	TSUNEQBD_A_MAIN10_Technicolor_2 \
	WP_B_Toshiba_3 \
	WP_MAIN10_B_Toshiba_3 \
	WPP_A_ericsson_MAIN10_2 \
	WPP_A_ericsson_MAIN_2 \
	WPP_B_ericsson_MAIN10_2 \
	WPP_B_ericsson_MAIN_2 \
	WPP_C_ericsson_MAIN10_2 \
	WPP_C_ericsson_MAIN_2 \
	WPP_D_ericsson_MAIN10_2 \
	WPP_D_ericsson_MAIN_2 \
	WPP_E_ericsson_MAIN10_2 \
	WPP_E_ericsson_MAIN_2 \
	WPP_F_ericsson_MAIN10_2 \
	WPP_F_ericsson_MAIN_2 \
"

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

RUST_BACKTRACE=full ccdec /opt/fluster/resources/VP9-TEST-VECTORS/vp90-2-14-resize-10frames-fp-tiles-8-1.webm/vp90-2-14-resize-10frames-fp-tiles-8-1.webm --output /dev/null --input-format vp9 --output-format i420

exit 0

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

