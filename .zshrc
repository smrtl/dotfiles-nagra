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

# ------------------------------------------------
# General aliases
# ------------------------------------------------

alias l="ls -a"
alias la="ls -al"
alias ll="ls -l"

alias gi="grep -i"

alias catc="pygmentize -g"
catnb() {cat $1 | jq -r '.cells[].source | join("--")'}

# Terraform/Terragrunt
alias tf="terraform"
alias tg="terragrunt"
alias tga="tg apply"

# Git
alias gb="git branch -vv"
alias gbclean="git checkout master && git pull && echo \"\\nDeleted branches:\" && git branch --merged | grep -v master | xargs git branch -d && echo \"\\nCurrent branches:\" && gb"
alias gbr="if [ -z \"\$(git status --porcelain)\" ]; then git checkout master && git pull && git checkout - && git rebase master -i; else echo Not clean; fi"

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
alias kgn="kg nodes -o custom-columns-file=$HOME/.config/k8s-node-columns.txt"
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
  local base
  if [ -n "$1" ]; then
    if [[ "$1" == "minikube" || "$1" == "local" ]]; then
      base="local"
    elif [ -f "$code/product-chart/envs/$1/kubeconfig.yaml" ]; then
      base="$code/product-chart"
    elif [ -f "$code/lab-chart/envs/$1/kubeconfig.yaml" ]; then
      base="$code/lab-chart"
    elif [ -f "$code/infra-chart/envs/$1/kubeconfig.yaml" ]; then
      base="$code/infra-chart"
    fi
    
    if [[ $base == "local" ]]; then
      export KUBECONFIG=""
      export KAFKA_CONNECT_URL=""
    elif [ -n "$base" ]; then
      local cluster="$base/envs/$1/kubeconfig.yaml"
      local secrets="$base/envs/$1/secrets.yaml"
      local secretsInfra="$base/envs/$1/secrets.infra.yaml"

      export KUBECONFIG="$cluster"

      if [ ! -f "$secretsInfra" ]; then
        echo "${fg[red]}Warning: infra secrets file '$secretsInfra' not found${reset_color}"
        export KAFKA_CONNECT_URL=""
      else
        local credentials=$(sops -d "$secretsInfra" | yq -r '.global.kafka_connect.url' | sed 's~^https://\([^:]*:[^@]*\)@.*$~\1~')
        export KAFKA_CONNECT_URL="http://$credentials@localhost:4443"
      fi

      if [ ! -f "$secrets" ]; then
        echo "${fg[red]}Warning: secrets file '$secrets' not found${reset_color}"
        export KAFKA_API_TOKEN=""
      else
        export KAFKA_API_TOKEN=$(sops -d "$secrets" | yq -r '.global.kafka.api_token')
      fi
    else
      echo "${fg[red]}Error: kubernetes cluster '$1' not found${reset_color}"
    fi
  fi

  echo -n "${fg[green]}Current context: "
  echo "${fg[cyan]}$(kubectl config current-context 2>/dev/null || echo none)${reset_color}"
}

kdeb() {
  local name=dbgdebian
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
      echo "    image: debian:10"
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
    echo "usage: kdeb [create|delete] [node_selector]"
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

# ------------------------------------------------
# Kafka
# ------------------------------------------------

kafka_proxy() {
  local proxy=$(kubectl get pods -o name | grep kafka-proxy-deploy)
  kubectl port-forward $proxy 4443
}

kafka_topics() {
  if [ -z "$1" ]; then
    echo "usage: kafka_ls_topics <env> [--token|--service|--info]"
    return 1
  fi

  local dir="$infra/terraform/$1"
  if [ ! -d "$dir" ]; then
    echo "invalid env '$1'"
    return 1
  fi
  
  cd $dir

  local token=$(sops -d secrets.tfvars.json | jq -r .aiven_api_token)
  local service=$(cat values.infra.yaml | yq -r .global.kafka.service)
  if [[ "$2" == "--token" ]]; then
    echo $token
  elif [[ "$2" == "--service" ]]; then
    echo $service
  else 
    local result=$(http https://api.aiven.io/v1/project/insight/service/$service/topic authorization:"aivenv1 $token")
    if [[ "$2" == "--info" ]]; then
      echo $result | jq
    else
      echo $result | jq -r '.topics[].topic_name'
    fi
  fi
}

kafka_connectors() {
  if [ -z "$1" ]; then
    echo "usage: kafka_connectors <env> [name]"
    return 1
  fi

  local dir="$infra/terraform/$1"
  if [ ! -d "$dir" ]; then
    echo "invalid env '$1'"
    return 1
  fi
  
  cd $dir

  local token=$(sops -d secrets.tfvars.json | jq -r .aiven_api_token)
  local service=$(cat values.infra.yaml | yq -r .global.kafka.service)

  if [ -z "$2" ]; then
    http https://api.aiven.io/v1/project/insight/service/$service/connectors authorization:"aivenv1 $token"
  else
    http https://api.aiven.io/v1/project/insight/service/$service/connectors/$2/status authorization:"aivenv1 $token"
  fi
}

kafka_clean() {
  if [ -z "$1" ]; then
    echo "usage: kafka_clean <env>"
    return 1
  fi

  local dir="$infra/terraform/$1"
  if [ ! -d "$dir" ]; then
    echo "invalid env '$1'"
    return 1
  fi
  
  kx $1
  cd $dir

  comm -23 \
    <(http $KAFKA_CONNECT_URL/connectors | jq -r '.[]' | sort) \
    <(terraform state list | grep topic | cut -d\" -f2 | sort | sed 's/^/s3-connect-by-date-/') | \
    grep -v 'test' | \
    read -d '' connectors

  echo "Will delete the following connectors:"
  echo $connectors
  echo
  echo "Do you wanna continue [yN] ?"
  read -r confirm
  [[ ! $confirm =~ ^[Yy]$ ]] && return 1
  echo
  for connector in $(echo $connectors | xargs); do
    echo "Deleting $connector ..."
    http DELETE $KAFKA_CONNECT_URL/connectors/$connector
  done
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
  export GITHUB_BOT_TOKEN=$(gopass show nexus/insight-ro)
}

pg() {
  if [ -z "$2" ]; then
    echo "Usage: $0 <data|bi> <env> [db_name]"
    return 1
  fi
  local key port env
  case $1 in
    data) key=pg_data_db; port=5432 ;;
    bi|redshift) key=bi_db; port=5439 ;;
    *) echo "Invalid db type."; return 1 ;;
  esac
  case $2 in
    us|pus|prod-us|production-us) env=production-us ;;
    p|prod|production) env=production ;;
    s|staging) env=staging ;;
    perf|perftest|dev) env=perftest ;;
    *) echo "Invalid env: $2"; return 1 ;;
  esac
  echo "Connecting to local ${fg[green]}$key$reset_color" \
       "with ${fg[green]}$env$reset_color credentials"
  local secrets="$code/product-chart/envs/$env/secrets.infra.yaml"
  PGPASSWORD=$(sops -d $secrets | yq -r ".global.$key.password") \
    psql -h localhost -p $port -U $(sops -d $secrets | yq -r ".global.$key.user") $3
}
