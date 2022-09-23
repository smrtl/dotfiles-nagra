# ------------------------------------------------
# Zinit
# ------------------------------------------------

ZINIT_HOME="${HOME}/.local/share/zinit"
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
zinit wait lucid for \
  OMZP::git \
  OMZP::colored-man-pages \
  atinit"export NVM_LAZY_LOAD=true" lukechilds/zsh-nvm \
  davidparsson/zsh-pyenv-lazy \
  atload"zicompinit; zicdreplay" blockf OMZL::completion.zsh

# Sdkman
zinit light-mode as"null" id-as'sdkman' run-atpull \
  atclone"curl https://get.sdkman.io/ | SDKMAN_DIR=$HOME/.sdkman bash" \
  atpull"SDKMAN_DIR=$HOME/.sdkman sdk selfupdate" \
  atinit"export SDKMAN_DIR=$HOME/.sdkman; source $HOME/.sdkman/bin/sdkman-init.sh" \
  for zdharma-continuum/null

# Keyboard, see https://coderwall.com/p/a8uxma/zsh-iterm2-osx-shortcuts
bindkey "[D" backward-word
bindkey "[C" forward-word
bindkey "^[a" beginning-of-line
bindkey "^[e" end-of-line

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

catnb() {cat $1 | jq -r '.cells[].source | join("--")'}

# Terraform/Terragrunt
alias tf="terraform"
alias tg="terragrunt"
alias tga="tg apply"

# terragrunt dir navigation
PRODUCT_INFRA_DIR="$code/product-infra"
TERRAGRUNT_LIVE_DIR="${PRODUCT_INFRA_DIR}/terraform/live"
alias tgprodeu="cd ${TERRAGRUNT_LIVE_DIR}/aws-prod/eu-west-1/production/"
alias tgprodus="cd ${TERRAGRUNT_LIVE_DIR}/aws-prod/us-east-1/production/"
alias tgstaging="cd ${TERRAGRUNT_LIVE_DIR}/aws-preprod/eu-west-1/staging/"
alias tgperftest="cd ${TERRAGRUNT_LIVE_DIR}/aws-dev/eu-west-1/perftest/"
alias tglabeu="cd ${TERRAGRUNT_LIVE_DIR}/aws-lab/eu-west-1/lab/"
alias tglabus="cd ${TERRAGRUNT_LIVE_DIR}/aws-lab/us-east-1/lab/"
alias tglabdevus="cd ${TERRAGRUNT_LIVE_DIR}/aws-dev/us-east-1/lab/"
alias tginfra="cd ${TERRAGRUNT_LIVE_DIR}/aws-lab/eu-west-1/infra/"
alias tglive="cd ${TERRAGRUNT_LIVE_DIR}"
alias tgmodules="cd ${PRODUCT_INFRA_DIR}/terraform/modules"

# Git
alias gbv="git branch -vv"
alias gbclean="gcm && git pull --prune && echo \"\\nCleaning merged branches:\" && git branch --merged | grep -v master | xargs git branch -d && echo \"\\nCurrent branches:\" && gb"
alias grbmi="if [ -z \"\$(git status --porcelain)\" ]; then gcm && gl && git checkout - && grbm -i; else echo Not clean; fi"

# Json logs
alias jlog="fblog"
alias jloga="fblog --dump-all"
alias jlogs="fblog -t@timestamp"
alias jlogp="fblog -tasctime -llevelname"

# ------------------------------------------------
# PyENV & Python
# ------------------------------------------------

alias brew='env PATH="${PATH//$PYENV_ROOT\/shims:/}" brew' # disable pyenv for brew

pyenv-brew-relink() {
  rm -f $PYENV_ROOT/versions/*-brew
  for version in $(brew --cellar)/python*/*; do
    if [ ! -e $version/bin/python ]; then
      ln -sf $version/bin/python3 $version/bin/python
    fi
    ln -sf "$version" "$PYENV_ROOT/versions/${version##*/}-brew"
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

# ------------------------------------------------
# AWS
# ------------------------------------------------

() {
  local -A _aws_config

  # avoid using aws-cli here as it is very slow
  _parse_ini $HOME/.aws/credentials _aws_config
  _parse_ini $HOME/.aws/config _aws_config

  export AWS_REGION="${_aws_config[default___region]}"
  export AWS_ACCESS_KEY_ID="${_aws_config[default___aws_access_key_id]}"
  export AWS_SECRET_ACCESS_KEY="${_aws_config[default___aws_secret_access_key]}"
  export AWS_PAGER=""
}

aws_profile() {
  if [ -n "$1" ]; then
    export AWS_PROFILE=$1
    export AWS_ACCESS_KEY_ID=$(aws configure get $1.aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get $1.aws_secret_access_key)
    export AWS_REGION=$(aws configure get $AWS_PROFILE.region || aws configure get default.region)
  fi

  echo "AWS profile: ${fg[green]}${AWS_PROFILE:-default}${reset_color}"
  echo "AWS region: ${fg[green]}${AWS_REGION}${reset_color}"
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
# Kubernetes
# ------------------------------------------------

kn() { if [ -n "$1" ]; then alias k="kubectl -n$1"; else alias k=kubectl; fi }
alias k=kubectl
alias ka="kubectl --all-namespaces=true"

alias kg="k get"
alias kgn="kg nodes -o custom-columns-file=$HOME/.config/k8s-node-columns.txt --sort-by=.metadata.creationTimestamp"
alias kgp="kg pods"
alias kgd="kg deployments"
alias kgs="kg services"
alias kgi="kg ingress"
alias kgj="kg job,cronjob"

alias wkgp="watch -n2 kubectl get pods"

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

alias ks="kubectl -nspark"
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
    elif [ -f "$code/insight-deploy/envs/$1/kubeconfig.yaml" ]; then
      export KUBECONFIG="$code/insight-deploy/envs/$1/kubeconfig.yaml"      
    else
      echo "${fg[red]}Error: kubernetes cluster '$1' not found${reset_color}"
    fi

    kubectl config use-context $(kubectl config get-contexts | awk '/kubernetes-admin/ {print $2}') \
      | sed "s~^\(.*\)\"\([^\"]*\)\"\(.*\)~${fg[green]}\1${fg[cyan]}\2${fg[green]}\3${reset_color}~"
  else
    echo "${fg[green]}Current context: ${fg[cyan]}$(kubectl config current-context)${reset_color}"
  fi
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

ksecret() {
  if [ -z "$1" ]; then echo "Usage: ksecret <secret> [key]"; return 1; fi
  local secret=$1
  local key=$2
  if [ -z "$key" ]; then
    echo "Available keys in '$secret':"
    kubectl get secret $secret -o jsonpath='{.data}' | jq -r 'keys[]'
  else
    kubectl get secret $secret -o jsonpath='{.data}' | jq -r ".$key" | base64 -D
  fi
}

# ------------------------------------------------
# NI
# ------------------------------------------------

ni_env() {
  echo "Exporting a bunch of secrets: CHART_REPO_PASSWORD, NOTEBOOK_USER_KEY, NOTEBOOK_USER_SECRET, LIVY_USER_KEY, LIVY_USER_SECRET, TRAININGMILL_QUAYIO_PASSWORD, NEXUS_INSIGHTRW_PWD, NEXUS_INSIGHTRO_PWD, GITHUB_BOT_TOKEN"
  export CHART_REPO_PASSWORD=$(gopass show nexus/insight-ro)
  export NOTEBOOK_USER_KEY="$(aws configure get default.aws_access_key_id)"
  export NOTEBOOK_USER_SECRET="$(aws configure get default.aws_secret_access_key)"
  export LIVY_USER_KEY="$(aws configure get default.aws_access_key_id)"
  export LIVY_USER_SECRET="$(aws configure get default.aws_secret_access_key)"
  export TRAININGMILL_QUAYIO_PASSWORD="$(gopass show quay.io/tokens/nagra+trainingmill)"
  export NEXUS_INSIGHTRW_PWD=$(gopass show nexus/insight-rw)
  export NEXUS_INSIGHTRO_PWD=$(gopass show nexus/insight-ro)
  export GITHUB_BOT_TOKEN=$(gopass -o show github.com/nagra-insight-bot/api_token)
  export GITHUB_TOKEN=$GITHUB_BOT_TOKEN
  export RENOVATE_TOKEN=$GITHUB_BOT_TOKEN
}

_tf_dir() {
  local account region env
  case $1 in
    us|pus|prod-us|production-us) account=aws-prod; region=us-east-1; env=production ;;
    p|prod|production) account=aws-prod; region=eu-west-1; env=production ;;
    s|staging) account=aws-preprod; region=eu-west-1; env=staging ;;
    perf|perftest|dev) account=aws-dev; region=eu-west-1; env=perftest ;;
    lab) account=aws-lab; region=eu-west-1; env=lab ;;
    lab-us) account=aws-lab; region=us-east-1; env=lab ;;
    *) _log_error "Invalid env: $1"; return 1 ;;
  esac
  local dir="$code/product-infra/terraform/live/$account/$region/$env"
  if [ ! -d "$dir" ]; then
    _log_error "Directory not found: $dir"
    return 1
  fi
  echo $dir
}

_values_dir() {
  local env
  case $1 in
    us|pus|prod-us|production-us) env=production-us ;;
    p|prod|production) env=production ;;
    s|staging) env=staging ;;
    perf|perftest|dev) env=perftest ;;
    *) _log_error "Invalid env: $1"; return 1 ;;
  esac
  local dir="$code/insight-deploy/envs/$env"
  if [ ! -d "$dir" ]; then
    _log_error "Directory not found: $dir"
    return 1
  fi
  echo $dir
}

pg() {
  if [ -z "$2" ]; then
    echo "Usage: $0 <data|bi> <env> [db_name]"
    return 1
  fi
  local key port
  case $1 in
    data) key=pg_data_db; port=5432 ;;
    bi|redshift) key=bi_db; port=5439 ;;
    *) echo "Invalid db type."; return 1 ;;
  esac

  local dir=$(_values_dir $2)
  [ -n "$dir" ] || return 1

  echo "Connecting to local ${fg[green]}$key$reset_color" \
       "with ${fg[green]}$(basename $dir)$reset_color credentials"
  local secrets="$code/insight-deploy/envs/$2/secrets.infra.yaml"
  if [ ! -f "$secrets" ]; then
    echo "Secret file '$secrets' not found, aborting."
    return 1
  fi

  PGPASSWORD=$(sops -d $secrets | yq -r ".global.$key.password") \
    psql -h localhost -p $port -U $(sops -d $secrets | yq -r ".global.$key.user") $3
}

alias kafka_pf='kubectl port-forward svc/ni-rta-kafka-proxy 4443'

kafka_url() {
  if [ -z "$1" ]; then echo "Usage: $0 <env>" && return 1; fi
  
  local values_dir=$(_values_dir $1)
  [ -n "$values_dir" ] || return 1
  
  sops -d "$values_dir/secrets.infra.yaml" \
    | yq -r '.global.kafka_connect.url' \
    | sed -E 's~https?://([^@]*)@.*~http://\1@localhost:4443~'
}

kafka_status() {
  if [ -z "$1" ]; then echo "Usage: $0 <env>" && return 1; fi

  local kafka_connect_url=$(kafka_url $1)
  for connector in $(http $kafka_connect_url/connectors | jq -r '.[]' | sort); do
    echo -n "$connector: "
    http $kafka_connect_url/connectors/$connector/status | jq -r '.connector.state'
  done
}

kafka_clean() {
  if [ -z "$1" ]; then echo "Usage: $0 <env>" && return 1; fi

  local tf_dir=$(_tf_dir $1)
  [ -n "$tf_dir" ] || return 1
  local values_dir=$(_values_dir $1)
  [ -n "$values_dir" ] || return 1

  _log_info "Starting kafka-connect port-forwarding ..."
  cleanup() { pkill -P $$;  }
  trap cleanup SIGINT SIGTERM EXIT
  KUBECONFIG="$values_dir/kubeconfig.yaml" kafka_pf &
  sleep 3

  _log_info "Retrieving kafka-connect connectors ..."
  local kafka_connect_url=$(sops -d "$values_dir/secrets.infra.yaml" \
    | yq -r '.global.kafka_connect.url' \
    | sed -E 's~https?://([^@]*)@.*~http://\1@localhost:4443~')
  local existing_connectors=$(http $kafka_connect_url/connectors | jq -r '.[]' | sort)

  _log_info "Retrieving configured connectors form terraform ..."
  local defined_connectors=$(cd "$tf_dir/ni_product" && terragrunt state list \
    | grep aiven_kafka_topic | cut -d\" -f2 | sort | sed 's/^/s3-connect-by-date-/')
  
  comm -23 \
    <(echo $existing_connectors) \
    <(echo $defined_connectors) | \
    read -d '' connectors

  _log_info "Will delete the following connectors:"
  echo $connectors
  echo
  echo "Do you wanna continue [yN] ?"
  read -r confirm
  [[ ! $confirm =~ ^[Yy]$ ]] && return 1

  echo
  for connector in $(echo $connectors | xargs); do
    _log_info "Deleting '$connector' ..."
    http DELETE "$kafka_connect_url/connectors/$connector"
  done
}
