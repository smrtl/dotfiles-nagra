# Language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Local bin (poetry, ...)
export PATH="$HOME/.local/bin:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Brew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# Personal env
export code=~/code
export ni=~/code/ni
export PATH="$code/bin:$PATH"

# Spark & Hadoop
export HADOOP_HOME=$code/bin/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_HOME=$code/bin/spark
export PATH=$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH
# export SPARK_DIST_CLASSPATH=$(hadoop classpath):$HADOOP_HOME/share/hadoop/tools/lib/*
# export SPARK_EXTRA_CLASSPATH=$SPARK_DIST_CLASSPATH

# Android
# export ANDROID_HOME="$code/bin/android"
# export PATH=$ANDROID_HOME/cmdline-tools/tools/bin/:$PATH
# export PATH=$ANDROID_HOME/emulator/:$PATH
# export PATH=$ANDROID_HOME/platform-tools/:$PATH
