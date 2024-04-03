# ------------------------------------------------
# Zinit
# ------------------------------------------------

ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# OMZ lib, no wait !
zinit for \
  OMZL::git.zsh \
  OMZL::history.zsh \
  OMZL::key-bindings.zsh \
  OMZL::prompt_info_functions.zsh \
  OMZL::theme-and-appearance.zsh

# Theme (modified OMZT::robbyrussell)
setopt promptsubst

PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT+='%{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

# Plugins
# - to enable NVM lazy load, add `atinit"export NVM_LAZY_LOAD=true"` before "lukechilds/zsh-nvm"
zinit wait lucid for \
  OMZP::git \
  OMZP::colored-man-pages \
  lukechilds/zsh-nvm \
  davidparsson/zsh-pyenv-lazy \
  atload"zicompinit; zicdreplay" blockf OMZL::completion.zsh

# Sdkman
zinit light-mode as"null" id-as'sdkman' run-atpull \
  atclone"curl https://get.sdkman.io/ | SDKMAN_DIR=$HOME/.sdkman bash" \
  atpull"SDKMAN_DIR=$HOME/.sdkman sdk selfupdate" \
  atinit"export SDKMAN_DIR=$HOME/.sdkman; source $HOME/.sdkman/bin/sdkman-init.sh" \
  for zdharma-continuum/null

# Spark env
zinit light-mode as"null" id-as'spark-init' \
  atload"export SPARK_DIST_CLASSPATH=$(hadoop classpath):$HADOOP_HOME/share/hadoop/tools/lib/*" \
  atload"export SPARK_EXTRA_CLASSPATH=\$SPARK_DIST_CLASSPATH" \
  for zdharma-continuum/null

# Keyboard, see https://coderwall.com/p/a8uxma/zsh-iterm2-osx-shortcuts
bindkey "[D" backward-word
bindkey "[C" forward-word
bindkey "^[a" beginning-of-line
bindkey "^[e" end-of-line

# Other ZSH opts
unsetopt autocd

# ------------------------------------------------
# Helper functions
# ------------------------------------------------

_parse_ini() {
  setopt localoptions extendedglob

  local __ini_file="$1" __out_hash="$2"
  local IFS='' __line __cur_section="" __access_string
  local -a match mbegin mend

  [[ ! -r "$__ini_file" ]] && \
    { builtin print -r "read-ini-file: an ini file is unreadable ($__ini_file)"; return 1; }

  while read -r -t 1 __line; do
      if [[ "$__line" = [[:blank:]]#(|\;*) ]]; then
          continue
      # Match "[Section]" line
      elif [[ "$__line" = (#b)[[:blank:]]#\[([^\]]##)\][[:blank:]]#(|\;*) ]]; then
          __cur_section="${match[1]}"
      # Match "string = string" line
      elif [[ "$__line" = (#b)[[:blank:]]#([^[:blank:]=]##)[[:blank:]]#[=][[:blank:]]#(*) ]]; then
          match[2]="${match[2]%"${match[2]##*[! $'\t']}"}" # remove trailing whitespace
          __access_string="${__out_hash}[${__cur_section}___${match[1]}]"
          : "${(P)__access_string::=${match[2]}}"
      fi
  done < "$__ini_file"

  return 0
}

_log_error() {
  echo "$fg[red]$@$reset_color" >&2
}

_log_info() {
  echo "$fg[green]$@$reset_color"
}

# ------------------------------------------------
# General aliases
# ------------------------------------------------

alias l="ls -a"
alias la="ls -al"
alias ll="ls -l"

alias gi="grep -i"

catnb() { cat $1 | jq -r '.cells[].source | join("--")' }

# Terraform/Terragrunt
alias tf="terraform"
alias tg="terragrunt"
alias tga="tg apply"

# Json logs
alias jlog="fblog"
alias jloga="fblog --dump-all"
alias jlogs="fblog -t@timestamp -a 'exception > stacktrace'"
alias jlogp="fblog -tasctime -llevelname -aexc_info"

# ------------------------------------------------
# Git & Github
# ------------------------------------------------

alias gbv="git branch -vv"
alias gbclean="gcm && git pull --prune && echo \"\\nCleaning merged branches:\" && git branch --merged | grep -v master | xargs git branch -d && echo \"\\nCurrent branches:\" && gb"
alias grbmi="if [ -z \"\$(git status --porcelain)\" ]; then gcm && gl && git checkout - && grbm -i; else echo Not clean; fi"

gfix() {
  local commit=$1
  if [ -z "${commit}" ]; then
    echo "Usage: gfix <commit>"
    return 1
  fi
  git commit --fixup ${commit}
  git rebase -i --autosquash ${commit}^
}

gh3rd() {
  local prs=()
  pushd "$ni/insight-deploy" >/dev/null

  # gather pull requests
  for arg in "$@"; do
    local filter='(.labels == []) and (.title | contains("third party"))'
    case "$arg" in
      i*)
        echo "Getting 3rd party charts PRs for infra env"
        filter+=' and (.title | contains("infra"))'
        ;;
      p*)
        echo "Getting 3rd party charts PRs for prod envs"
        filter+=' and (.title | contains("production"))'
        ;;
      l*)
        echo "Getting 3rd party charts PRs for lab envs"
        filter+=' and (.title | contains("lab"))'
        ;;
      *)
        echo "Getting 3rd party charts PRs for dev envs"
        filter+=' and ((.title | contains("dev")) or (.title | contains("staging")))'
        ;;
    esac
    prs+=($(gh pr list --json number,title,labels --jq '.[] | select('$filter') | .number'))
  done

  # merging PRs
  for pr in "${prs[@]}"; do
    gh pr view $pr

    echo -n "Merge ? (y/any) "
    read confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      gh pr merge -m -d $pr
    fi
  done

  popd >/dev/null
}


# ------------------------------------------------
# General Helpers
# ------------------------------------------------

parse_ts() {
  TZ=UTC date -r $(( $1 > 100000000000 ? $1/1000 : $1 ))
}

to_ts() {
  TZ=UTC date -j -f "%Y-%m-%d %H:%M:%S" "$@" +"%s"
}

parse_jwt() {
  echo $1 | jq -R 'split(".") | .[0],.[1] | @base64d | fromjson'
}

# ------------------------------------------------
# PyENV, Python & Micromamba
# ------------------------------------------------

alias brew='env PATH="${PATH//$PYENV_ROOT\/shims:/}" brew' # disable pyenv for brew

pyenv-brew-relink() {
  rm -f $PYENV_ROOT/versions/*-brew

  for version in $(brew --cellar)/python*/*; do
    version_num="${${version##*@}%%/*}"
    python_bin="bin/python${version_num}"

    if [ -e "$version/$python_bin" ]; then
      # Python binary found
      echo "Found ${version##*/}"
      if [ ! -e "$version/bin/python" ]; then ln -sf "$version/$python_bin" "$version/bin/python"; fi
      if [ ! -e "$version/bin/python3" ]; then ln -sf "$version/$python_bin" "$version/bin/python3"; fi
      ln -sf "$version" "$PYENV_ROOT/versions/${version##*/}-brew"
    fi
  done

  pyenv rehash
  pyenv versions
}

# Python venv
venv() {
  local name=$1
  if [ -z "$name" ]; then
    [ -d venv ] && name=venv || name=.venv
  fi
  if [ ! -d $name ]; then
    echo "creating a new venv in '$PWD/$name'"
    python3 -m venv $name
  fi
  source $name/bin/activate
}

# Micromamba
# Generated with: micromamba shell init -s zsh -p ~/.micromamba
export MAMBA_EXE="/opt/homebrew/opt/micromamba/bin/micromamba";
export MAMBA_ROOT_PREFIX="/Users/samuel.suter/.micromamba";
eval "$("$MAMBA_EXE" shell hook --shell zsh --prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
alias mamba=micromamba

# ------------------------------------------------
# AWS
# ------------------------------------------------

aws_secret() {
  if [ -z "$1" ]; then
    aws secretsmanager list-secrets --profile 580978913621-admin | jq -r '.SecretList[].Name'
  else
    aws secretsmanager get-secret-value --profile 580978913621-admin \
      --query 'SecretString' --output text --secret-id $1 | jq -r ".$2"
  fi
}

# aws_profile <env> [<env>]
# gets the aws profile corresponding the the env/location
aws_profile() {
  local profile
  while [[ $# -gt 0 ]]; do
    case "$1" in
      d*) profile=301882015541 ;;
      l*) profile=580978913621 ;;
      s*) profile=528524992932 ;;
      p*) profile=056782732132 ;;
      down*) profile=056782732132 ;;
      up*) profile=056782732132 ;;
      altice-lab) profile=882571264765 ;;
    esac
    if [ -n "$profile" ]; then
      echo -n $profile
      break
    fi
    shift
  done
}

# aws_region <env>
# gets the aws region corresponding to the env/location
aws_region() {
  case "$1" in
    *-us) echo us-east-1 ;;
    *) echo eu-west-1 ;;
  esac
}

# aws_ssh <env> <instance>
# SSH into an EC2 instance using SSM
aws_ssh() {
  aws \
    ssm start-session \
    --profile $(aws_profile $1)-admin \
    --region $(aws_region $1) \
    --target $2
}

s3() {
  local default_profile=882571264765

  # args processing
  local ni_bucket_pattern='(^|^s3.?://)ni-data-([^-]+)-([^/-]+)(/.*)?$'
  local s3_uri='^s3.?(://.+)$'
  local env=
  local customer=
  local profile=
  local profile_next=
  local profile_suffix=
  local aws_cli_args=()

  for arg in "$@"; do
    if [[ $profile_next -gt 0 ]]; then
      profile=$arg
      profile_next=
    elif [[ $arg == "--admin" ]]; then  # custom arg to use admin profiles
      profile_suffix=-admin
    elif [[ $arg == "--profile" ]]; then  # catch manually specified profile
      profile_next=1
    elif [[ $arg =~ $ni_bucket_pattern ]]; then  # ni bucket detected
      customer=$match[2]
      env=$match[3]
      aws_cli_args+=("s3://ni-data-$customer-$env${match[4]}")
    elif [[ $arg =~ $s3_uri ]]; then  # s3 uri
      aws_cli_args+=("s3${match[1]}")
    else
      aws_cli_args+=($arg)
    fi
  done

  if [ -z "$profile" ]; then
    profile=$(aws_profile "$customer-$env" "$env")
    profile=${profile:-$default_profile}${profile_suffix}
  fi

  local cmd=(aws s3 --profile $profile ${aws_cli_args})
  echo "${fg[gray]}${cmd}${reset_color}" >&2
  $cmd
}

s3a() {
  s3 --admin $@
}

# see https://serverfault.com/questions/679989/most-efficient-way-to-batch-delete-s3-files
aws_ls() {
  if [ -z "$1" ]; then
    echo "usage: aws_ls <bucket> [prefix]"
    return 1
  fi

  local -a extra_args
  if [ -n "$2" ]; then
    extra_args+=(--prefix $2)
  fi

  aws s3api list-objects \
    --profile ${AWS_PROFILE:-default} \
    --output text --bucket $1 ${extra_args[@]} --query 'Contents[].[Key]'
}

# see https://serverfault.com/questions/679989/most-efficient-way-to-batch-delete-s3-files
aws_rm() {
  if [ -z "$1" ]; then
    echo "usage: aws_rm <bucket> [file-of-keys]"
    return 1
  fi
  if [ -n "$2" ] && [ ! -f "$2" ]; then
    echo "Error: file $2 not found"
    return 1
  fi

  local command="aws s3api delete-objects \
    --profile ${AWS_PROFILE:-default} --bucket $1 \
    --delete \"Objects=[\$(printf \"{Key=%s},\" \"\$@\")],Quiet=true\""
  cat $2 | xargs -P8 -n1000 bash -c "$command" _
}

aws_spark() {
  if [ -z $1 ]; then
    echo "Usage: $0 <profile_name>"
    return 1
  fi

  echo -e "${fg[green]}Getting token for profile $1 ...${reset_color}"
  local role=$(aws configure get $1.role_arn)
  if [ -z "$role" ]; then
    echo "Role not found"
    return 1
  fi
  local token=$(aws sts assume-role --role-arn $role --role-session-name s3_access --duration 900)
  local access_key_id=$(echo $token | jq -r .Credentials.AccessKeyId)
  local secret_access_key=$(echo $token | jq -r .Credentials.SecretAccessKey)
  local session_token=$(echo $token | jq -r .Credentials.SessionToken)
  local expiration=$(echo $token | jq -r .Credentials.Expiration)
  
  echo -e "${fg[green]}Starting spark shell, token will expire at: $expiration${reset_color}\n"
  spark-shell \
    --conf "spark.hadoop.fs.s3a.aws.credentials.provider=org.apache.hadoop.fs.s3a.TemporaryAWSCredentialsProvider" \
    --conf "spark.hadoop.fs.s3a.access.key=$access_key_id" \
    --conf "spark.hadoop.fs.s3a.secret.key=$secret_access_key" \
    --conf "spark.hadoop.fs.s3a.session.token=$session_token"
}

# ------------------------------------------------
# Kubernetes & Heml
# ------------------------------------------------

export KUBECONTEXT=admin

alias helm="/opt/homebrew/bin/helm --kube-context $KUBECONTEXT"
alias k9s="/opt/homebrew/bin/k9s --context $KUBECONTEXT"

kn() {
  if [ -n "$1" ]; then
    export KUBECMD="kubectl --context $KUBECONTEXT -n$1"
  else
    export KUBECMD="kubectl --context $KUBECONTEXT"
  fi
  alias k="$KUBECMD"
}
kn
alias ka="k --all-namespaces=true"

alias kg="k get"

kgn() {
  kg nodes -o json | jq -r '
    ([["NAME", "ID", "TYPE", "PROVISIONER", "CREATION"]], (
      .items | map(
        select(.spec.providerID | contains("i-")) | [
          .metadata.name,
          (.spec.providerID | capture("/(?<i>[^/]+$)")["i"]),
          .metadata.labels["node.kubernetes.io/instance-type"],
          .metadata.labels["karpenter.sh/provisioner-name"],
          .metadata.creationTimestamp
        ]
      ) | sort_by(.[3], .[2], .[4])
    ))[] | [
      (.[0] | . + (" " * (30 - length))),
      (.[1] | . + (" " * (20 - length))),
      (.[2] | . + (" " * (12 - length))),
      (.[3] | . + (" " * (32 - length))),
      .[4]
    ] | join(" ")
  '
}

alias kgp="kg pods"
alias kgd="kg deployments"
alias kgs="kg services"
alias kgi="kg ingress"
alias kgj="kg job,cronjob"

alias wkgp="watch -n2 $KUBECMD get pods"
alias kgiv="kgi -ojson | jq -r '.items[] | [.metadata.name,.spec.rules[0].host//\"(none)\",.spec.rules[0].http.paths[0].path,.metadata.annotations[\"konghq.com/plugins\"]] | @tsv' | column -t"

alias kd="k describe"
alias kdn="kd node"
alias kdp="kd pod"
alias kdd="kd deployment"
alias kds="kd service"
alias kdi="kd ingress"

alias ke="k edit"
alias ken="ke node"
alias kep="ke pod"
alias ked="ke deployment"
alias kes="ke service"
alias kei="ke ingress"

alias kl="k logs"
alias klf="kl -f"
alias kpf="k port-forward"

alias ks="k -nspark"
alias ksg="ks get"
alias ksgp="ksg pods"
alias ksd="ks describe"
alias ksdp="ksd pod"
alias kse="ks edit"
alias ksep="ks edit pod"
alias ksl="ks logs"
alias kslf="ks logs -f"
alias kspf="ks port-forward"

kx() {
  if [ -n "$1" ]; then
    if [[ "$1" == "minikube" || "$1" == "local" ]]; then
      export KUBECONFIG=""
    elif [ -f "$ni/insight-deploy/envs/$1/kubeconfig.yaml" ]; then
      export KUBECONFIG="$ni/insight-deploy/envs/$1/kubeconfig.yaml"      
    else
      echo "${fg[red]}Error: kubernetes cluster '$1' not found${reset_color}"
    fi
  fi

  local current=$(k config get-contexts | grep '*')
  if [ -z "$current" ]; then
    echo "${fg[yellow]}No context${reset_color}"
  else
    echo "${fg[green]}Current context: ${fg[cyan]}$(echo $current | awk '{print $2 " (" $3 ", " $4 ")"}')${reset_color}"
  fi
}

# use AWS SSM to SSH to a k8s node
kssh() {
   aws --profile $(k config current-context | rev | cut -d '-' -f2- | rev) ssm start-session --target $(k get node $1 -ojson | jq -r ".spec.providerID" | cut -d \/ -f5)
}

kdev() {
  local name=dev-sam
  for v in "$@"; do declare "${v%%=*}=${v#*=}"; done

  if [ $# -eq 0 ]; then
    local pod=$(kgp -l app=$name -o name)
    if [ -z "$pod" ]; then
      echo "$name not found, please create it first (kdeb create)"
    else
      echo "found $pod, starting bash..."
      k exec -ti $pod -- bash
    fi
  elif [[ $1 == "create" ]]; then
    (
      echo "apiVersion: v1"
      echo "kind: Pod"
      echo "metadata:"
      echo "  name: $name"
      echo "  labels:"
      echo "    app: $name"
      echo "spec:"
      if [ -n "$label" ]; then
        echo "  nodeSelector:"
        echo "    ${label%%=*}: \"${label#*=}\""
      fi
      echo "  containers:"
      echo "  - name: debian"
      echo "    image: smrtl/debian-dev"
      echo '    command: ["/bin/sh"]'
      echo '    args: ["-c", "while true; do sleep 10; done"]'
      if [ -n "$toleration" ]; then
        echo '  tolerations:'
        echo "  - key: \"${toleration%%=*}\""
        echo "    operator: \"Equal\""
        echo "    value: \"${toleration#*=}\""
        echo "    effect: \"NoSchedule\""
      fi
    ) | k create -f -
  elif [[ $1 == "delete" ]]; then
    k delete pod $name
  else
    echo "usage: kdeb [create|delete] [label=key=value] [toleration=key=value]"
  fi
}

kproxy() {
  local name=dbgproxy
  if [[ $1 == "create" ]] && [ $# -ge 3 ]; then
    local target_host=$2
    local target_port=$3
    local port=${4:-$3}
    (
      echo "apiVersion: v1"
      echo "kind: Pod"
      echo "metadata:"
      echo "  name: $name"
      echo "  labels:"
      echo "    app: $name"
      echo "spec:"
      echo "  containers:"
      echo "  - name: socat"
      echo "    image: alpine/socat:1.0.5"
      echo "    args:"
      echo "    - tcp-listen:$port,fork,reuseaddr"
      echo "    - tcp-connect:$target_host:$target_port"
      echo "    ports:"
      echo "    - containerPort: $port"
      echo "      protocol: TCP"
    ) | k create -f -
  elif [[ $1 == "delete" ]]; then
    k delete pod $name
  else
    echo "usage:"
    echo "  kproxy create <target_host> <target_port> [port]"
    echo "  kproxy delete"
  fi
}

ksshd() {
  local name=${2:-dbgsshd}
  if [[ $1 == "create" ]]; then
    (
        echo "apiVersion: v1"
        echo "kind: Pod"
        echo "metadata:"
        echo "  name: $name"
        echo "  labels:"
        echo "    app: $name"
        echo "spec:"
        echo "  containers:"
        echo "  - name: main"
        echo "    image: smrtl/debian-sshd"
        echo "    ports:"
        echo "    - containerPort: 2222"
        echo "      protocol: TCP"
    ) | k create -f -
  elif [[ $1 == "delete" ]]; then
    k delete pod $name
  else
    echo "usage:"
    echo "  kproxy create [name]"
    echo "  kproxy delete [name]"
  fi
}

# ksecret [secret] [key]
ksecret() {
  local secret=$1
  local key=$2
  if [ -z "$secret" ]; then
    k get secret
  elif [ -z "$key" ]; then
    k get secret $secret -o jsonpath='{.data}' | jq 'to_entries | map({(.key): .value | @base64d}) | add'
  else
    k get secret $secret -o jsonpath="{.data.${key//./\\.}}" | base64 -D
  fi
}

# ------------------------------------------------
# NI
# ------------------------------------------------

ni_env() {
  echo "Exporting the following secrets in env:"
  echo " - NOTEBOOK_USER_KEY"
  echo " - NOTEBOOK_USER_SECRET"
  echo " - LIVY_USER_KEY"
  echo " - LIVY_USER_SECRET"
  echo " - TRAININGMILL_DOCKER_PASSWORD"
  echo " - NEXUS_INSIGHTRW_PWD"
  echo " - NEXUS_INSIGHTRO_PWD"
  echo " - POETRY_HTTP_BASIC_NEXUS_USERNAME"
  echo " - POETRY_HTTP_BASIC_NEXUS_PASSWORD"
  echo " - GITHUB_BOT_TOKEN"
  echo " - GITHUB_TOKEN"
  echo " - RENOVATE_TOKEN"
  # AWS
  export NOTEBOOK_USER_KEY="$(aws configure get default.aws_access_key_id)"
  export NOTEBOOK_USER_SECRET="$(aws configure get default.aws_secret_access_key)"
  export LIVY_USER_KEY="$(aws configure get default.aws_access_key_id)"
  export LIVY_USER_SECRET="$(aws configure get default.aws_secret_access_key)"
  # Trainingmill
  export TRAININGMILL_DOCKER_PASSWORD="$(aws_secret quayio/trainingmill token)"
  # Nexus
  export NEXUS_INSIGHTRW_PWD=$(aws_secret nexus/insight-rw password)
  export NEXUS_INSIGHTRO_PWD=$(aws_secret nexus/insight-ro password)
  export POETRY_HTTP_BASIC_NEXUS_USERNAME=insight-ro
  export POETRY_HTTP_BASIC_NEXUS_PASSWORD=$NEXUS_INSIGHTRO_PWD
  export POETRY_HTTP_BASIC_NEXUS_PASSWORD=$NEXUS_INSIGHTRO_PWD
  export PIP_INDEX_URL=https://${NEXUS_INSIGHTRO_USERNAME}:${NEXUS_INSIGHTRO_PWD}@nexus.infra.nagra-insight.com/repository/pypi-group/simple/
  # Github
  export GITHUB_BOT_TOKEN=$(aws_secret github/nagra-insight-bot api_token)
  export GITHUB_TOKEN=$GITHUB_BOT_TOKEN
  export RENOVATE_TOKEN=$GITHUB_BOT_TOKEN
}

