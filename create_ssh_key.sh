#!/bin/sh

ssh-keygen -t rsa -b 4096 -C "michaelmeadows@gmail.com" -N '' -f ~/.ssh/github_rsa <<< y

echo ''
echo 'Copy the text below (after the line of equals)'
echo '=============================================='

tail ~/.ssh/github_rsa.pub
