#!/usr/bin/env bash

 htpasswd -cbB users.htpasswd admin1 dontcare
 htpasswd -bB users.htpasswd alice dontcare
 htpasswd -bB users.htpasswd bob dontcare
 htpasswd -bB users.htpasswd carol dontcare
 htpasswd -bB users.htpasswd dave dontcare
 htpasswd -bB users.htpasswd ernie dontcare
 htpasswd -bB users.htpasswd fay dontcare

 oc create secret generic test-users-htpasswd --from-file=htpasswd=users.htpasswd -n openshift-config --dry-run=client -o yaml | oc apply -f -
