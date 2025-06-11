env/env.outline env/env.minio:
	@bash makefile.sh create_env_files

data/certs/dhparam.pem:
	mkdir -p data/certs
	openssl dhparam -out data/certs/dhparam.pem 2048

env/env.slack data/certs/private.key data/certs/public.crt: env/env.outline data/certs/dhparam.pem
	@bash makefile.sh generate_https_conf

.PHONY: init-data-dirs install start logs stop clean-docker clean-env clean-data

init-data-dirs: env/env.outline
	@bash makefile.sh init_data_dirs

install: env/env.outline env/env.minio env/env.slack init-data-dirs data/certs/private.key data/certs/public.crt
	@echo "=>run 'make start' and your server should be ready shortly."

# Docker
start: install
	cd docker && docker-compose up -d

logs:
	cd docker && docker-compose logs -f

stop:
	cd docker && docker-compose down || true

# Cleanup targets
clean-docker: stop
	cd docker && docker-compose rm -fsv || true

clean-env:
	@bash makefile.sh delete_env

clean-data:
	@bash makefile.sh delete_data