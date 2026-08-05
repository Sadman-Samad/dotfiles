#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="/home/sadman/.local/bin:/opt/flutter/bin:$PATH"

# Android SDK & JDK
export ANDROID_HOME=/home/sadman/android-sdk
export ANDROID_SDK_ROOT=/home/sadman/android-sdk
export JAVA_HOME=/home/sadman/android-sdk/jdk-17.0.13+11
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
