set -x

read -p "Press Enter to delete the workshop and it's resources. <CTRL-C> to quit" CONTINUE
kapp delete -n tap-install -a cartographer-workshops --yes

