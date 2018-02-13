destroy:
	@vagrant destroy -f
	@rm -rf tmp_deploying_stage
	@rm -rf *.vdi

create:
	@vagrant up -d

recreate:
	@make destroy
	@make create

stop:
	@VBoxManage controlvm minio-4 acpipowerbutton || true
	@VBoxManage controlvm minio-3 acpipowerbutton || true
	@VBoxManage controlvm minio-2 acpipowerbutton || true
	@VBoxManage controlvm minio-1 acpipowerbutton || true

start:
	@VBoxManage startvm minio-1 --type headless || true
	@sleep 10
	@VBoxManage startvm minio-2 --type headless || true
	@VBoxManage startvm minio-3 --type headless || true
	@VBoxManage startvm minio-4 --type headless || true

status:
	@VBoxManage list runningvms
