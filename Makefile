# --------------------------------------------------------------------
# Copyright (c) 2019 THE ABSTRACT CONNECTION, The France. All Rights Reserved.
# Author(s): Anthony Potappel
# 
# This software may be modified and distributed under the terms of the
# MIT license. See the LICENSE file for details.
# --------------------------------------------------------------------

SHELL := /bin/bash

# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

# PROJECT_NAME defaults to name of the current directory.
# should not to be changed if you follow GitOps operating procedures.
ifeq ($(project_name), )
PROJECT_NAME = $(notdir $(PWD))
else
PROJECT_NAME := $(project_name)
endif

# Note. If you change this, you also need to update docker-compose.yml.
# only useful in a setting with multiple services/ makefiles.
ifeq ($(target), )
SERVICE_TARGET := main
else
SERVICE_TARGET := $(target)
endif

# if vars not set specifially: try default to environment, else fixed value.
# strip to ensure spaces are removed in future editorial mistakes.
# tested to work consistently on popular Linux flavors and Mac.
ifeq ($(user),)
# USER retrieved from env, UID from shell.
HOST_USER ?= $(strip $(if $(USER),$(USER),nodummy))
HOST_UID ?= $(strip $(if $(shell id -u),$(shell id -u),4000))
else
# allow override by adding user= and/ or uid=  (lowercase!).
# uid= defaults to 0 if user= set (i.e. root).
HOST_USER = $(user)
HOST_UID = $(strip $(if $(uid),$(uid),0))
endif

THIS_FILE := $(lastword $(MAKEFILE_LIST))
CMD_ARGUMENTS ?= $(cmd)

# source Makefile_scripts.sh 
# extract services_name from docker-compose.yml and assign it to SERVICES_ARRAY
SERVICE_LIST := $(shell source $(PWD)/Makefile_scripts.sh && dc_get_services_names docker-compose.yml)
SERVICE_LIST_WITH_IMAGE := $(shell source $(PWD)/Makefile_scripts.sh && dc_get_services_names_with_images docker-compose.yml)

# export such that its passed to shell functions for Docker to pick up.
export PROJECT_NAME
export HOST_USER
export HOST_UID

# all our targets are phony (no files to check).
.PHONY: shell help build rebuild service login test clean prune

# suppress makes own output
#.SILENT:

# shell is the first target. So instead of: make shell cmd="whoami", we can type: make cmd="whoami".
# more examples: make shell cmd="whoami && env", make shell cmd="echo hello container space".
# leave the double quotes to prevent commands overflowing in makefile (things like && would break)
# special chars: '',"",|,&&,||,*,^,[], should all work. Except "$" and "`", if someone knows how, please let me know!).
# escaping (\) does work on most chars, except double quotes (if someone knows how, please let me know)
# i.e. works on most cases. For everything else perhaps more useful to upload a script and execute that.
shell:
ifeq ($(CMD_ARGUMENTS),)
	# ☠☠☠ NO COMMAND GIVEN DEFAULT TO SHELL
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh
else
	# ☠☠☠ RUN THE COMMAND
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh -c "$(CMD_ARGUMENTS)"
endif

# Regular Makefile part for buildpypi itself
help:
	@echo ''
	@echo 'Usage: make [TARGET] [EXTRA_ARGUMENTS]'
	@echo 'Targets:'
	@echo '  build    build docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  rebuild  rebuild docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  test     test docker --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  service  run as service --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  login   	run as service and login --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  clean    remove docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  prune    shortcut for docker system prune -af. Cleanup inactive containers and cache.'
	@echo '  shell    run docker --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo ''
	@echo 'Extra arguments:'
	@echo 'cmd=:	make cmd="whoami"'
	@echo '# user= and uid= allows to override current user. Might require additional privileges.'
	@echo 'user=:	make shell user=root (no need to set uid=0)'
	@echo 'uid=:	make shell user=dummy uid=4000 (defaults to 0 if user= set)'

rebuild:
	# ☠☠☠ FORCE REBUILD
	docker-compose build --no-cache $(SERVICE_TARGET)

service:
	# ☠☠☠ RUN AS A BACKGROUND SERVICE
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) up -d $(SERVICE_TARGET)

unservice:
	# ☠☠☠ STOP THE BACKGROUND SERVICE
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) down

login: service
	# ☠☠☠ RUN AS SERVICE & ATTACH TO IT
	docker exec -it $(PROJECT_NAME)_$(HOST_UID) sh

pullimages: 
	# ☠☠☠ PULL ALL NEEDED IMAGES
	$(foreach element,$(SERVICE_LIST_WITH_IMAGE),$(shell export PROJECT_NAME=$(PROJECT_NAME) export HOST_USER=$(HOST_USER) export HOST_UID=$(HOST_UID) && docker-compose pull $(element)))	

build:
	# ☠☠☠ BUILD CONTAINER & DEPENDECES CONTAINERS
	docker-compose build $(SERVICE_TARGET)

clean:
	# ☠☠☠ REMOVE CREATED IMAGES
	@docker-compose -p $(PROJECT_NAME)_$(HOST_UID) down --remove-orphans --rmi all 2>/dev/null \
	&& echo 'Image(s) for "$(PROJECT_NAME):$(HOST_USER)" removed.' \
	|| echo 'Image(s) for "$(PROJECT_NAME):$(HOST_USER)" already removed.'

prune:
	# ☠☠☠ CLEAN ALL THAT IS NOT ACTIVELY USED
	docker system prune -af

test:
	# ☠☠☠ RUN TESTS (ADD YOUR OWN TEST)
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) run --rm $(SERVICE_TARGET) sh -c '\
		echo "I am `whoami`. My uid is `id -u`." && echo "Docker runs!"' \
	&& echo success

postinstall:
	# ☠☠☠ RUN POST-INSTALL SCRIPT
	./post-install.sh
