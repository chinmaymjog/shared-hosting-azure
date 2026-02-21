This is the to-do list for the Azure Lamp Hosting project.

- [ ] Write readme
- [ ] Architecture diagram

cd cicd-toolkit
docker build --platform=linux/amd64 -t <your repo>:<tag> .
docker push <your repo>:<tag>

docker pull chinmaymjog/cicd-toolkit:latest

cd jenkins-ansible
docker build --platform=linux/amd64 -t <your repo>:<tag> .
docker push <your repo>:<tag>

docker pull chinmaymjog/jenkins-ansible:latest

cd ../ter
ssh -i webadmin_rsa webadmin@135.235.171.0
curl -fsSL https://test.docker.com -o test-docker.sh
sudo sh test-docker.sh

sudo usermod -aG docker webadmin

Log out & login

chmod 600 ~/.ssh/id_rsa

cf22cbd43ced43638867d1ca2f0570b4
