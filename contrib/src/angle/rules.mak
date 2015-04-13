# angle

ANGLE_URL := https://github.com/MSOpenTech/angle.git

$(TARBALLS)/angle-git.tar.xz:
	$(call download_git,$(ANGLE_URL),ms-master,ddbf057c52)

.sum-angle: angle-git.tar.xz
	$(warning $@ not implemented)
	touch $@

angle: angle-git.tar.xz .sum-angle
	$(UNPACK)
	$(MOVE)

.angle: angle toolchain.cmake
	cd $< && $(HOSTVARS) ${CMAKE} -DFLATBUFFERS_BUILD_TESTS=OFF
	cd $< && $(MAKE)  VERBOSE=1 install
	touch $@