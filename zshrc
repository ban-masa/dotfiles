export LANG=ja_JP.UTF-8

eval "$(dircolors -b)"

autoload colors
colors

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_no_store
setopt appendhistory             # HISTFILEを上書きせずに追記
setopt hist_ignore_all_dups         # 重複したとき、古い履歴を削除
setopt hist_ignore_space         # 先頭にスペースを入れると履歴を保存しない
setopt hist_reduce_blanks           # 余分なスペースを削除して履歴を保存
setopt share_history             # 履歴を共有する

autoload -Uz vcs_info

zstyle ':vcs_info:*' formats '[%b]'
zstyle ':vcs_info:*' actionformats '[%b|%a]'

# PROMPTの設定
PROMPT="%B%{${fg[white]}%}[%~]%{${reset_color}%}%b
%{${fg[yellow]}%}$%{${reset_color}%} "
PROMPT2="%B%{${fg[yellow]}%}%_>%{${reset_color}%}%b "
# バージョン管理されているディレクトリにいれば表示，そうでなければ非表示
RPROMPT="%1(v|%F{white}%1v%f|)"
## 入力が右端まで来たらRPROMPTを消す
setopt transient_rprompt
setopt prompt_subst

function precmd() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
    echo -ne "\033]0;${USER}@${HOST}\007"
}

# コマンド補完の強化
if [ -d "$HOME/.zsh-setting/" ]; then
    fpath=(~/.zsh-setting/completion $fpath)
fi

# 補完
autoload -Uz compinit
compinit -u
## 補完候補を一覧表示
setopt auto_list
## TAB で順に補完候補を切り替える
setopt auto_menu
## 補完候補一覧でファイルの種別をマーク表示
setopt list_types
## カッコの対応などを自動的に補完
setopt auto_param_keys
## ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt auto_param_slash
## 補完候補のカーソル選択を有効に
zstyle ':completion:*:default' menu select=2
## 補完候補の色づけ
export ZLS_COLORS=$LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
## 補完候補を詰めて表示
setopt list_packed
## スペルチェック
setopt correct
## ファイル名の展開でディレクトリにマッチした場合末尾に / を付加する
setopt mark_dirs
## 最後のスラッシュを自動的に削除しない
setopt noautoremoveslash
## 大文字と小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
## 出力の文字列末尾に改行コードが無い場合でも表示
unsetopt promptcr
## ビープを鳴らさない
setopt nobeep
## cd 時に自動で push
setopt auto_pushd
## 同じディレクトリを pushd しない
setopt pushd_ignore_dups
## --prefix=/usr などの = 以降も補完
setopt magic_equal_subst
## ファイル名の展開で辞書順ではなく数値的にソート
setopt numeric_glob_sort
## 出力時8ビットを通す
setopt print_eight_bit
## ディレクトリ名だけで cd
setopt auto_cd
## コマンドラインでも # 以降をコメントと見なす
setopt interactive_comments

# 補完候補をhjklで選ぶ
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Ctrl+PとCtrl+Nで履歴を検索
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# ^で上のディレクトリへ
function cdup-or-insert-circumflex() {
    if [[ -z "$BUFFER" ]]; then
        echo
        cd ..
        zle reset-prompt
    else
        zle self-insert '^'
    fi
}
zle -N cdup-or-insert-circumflex
bindkey '\^' cdup-or-insert-circumflex

function chpwd() {
    ls --color=auto -C
}

function search-rostopic-by-percol() {
  LBUFFER=$LBUFFER$(rostopic list | percol)
  zle -R -c
}
zle -N search-rostopic-by-percol
bindkey '^[r' search-rostopic-by-percol

# [[ -z "$TMUX" && -z "$WINDOW" && ! -z "$PS1" ]] && tmux

HARDCOPYFILE=/tmp/tmux-hardcopy
touch $HARDCOPYFILE

dabbrev-complete () {
  local reply lines=80

  tmux capture-pane && tmux save-buffer -b 0 $HARDCOPYFILE && tmux delete-buffer -b 0
  reply=($(sed '/^$/d' $HARDCOPYFILE | sed '$ d' | tail -$lines))

  compadd -Q - "${reply[@]%[*/=@|]}"
}

zle -C dabbrev-complete menu-complete dabbrev-complete
bindkey '^o' dabbrev-complete
bindkey '^o^_' reverse-menu-complete

if [ "$EMACS" ];then
  alias roseus='roseus'
else
  alias roseus="rlwrap -c -b '(){}.,;|' -a -pGREEN roseus"
fi

function random-editor () {
  if [ $(($RANDOM % 100)) -lt 50 ];then
    vim $1
  else
    emacs -nw $1
  fi
}

function rossetrhp4b() {
  rossetmaster 192.168.96.200
  rossetip
}

function rossetrhp3() {
  rossetmaster 192.168.96.204
  rossetip
}

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias g++='g++ -std=c++11 -Wall -Wextra -Wconversion'
alias :q='echo ここVimじゃねーから'
alias eus='roseus "(jsk)" "(rbrain)"'
alias lvim='vim -l'
alias eagle='~/eagle-7.3.0/bin/eagle'
alias python='rlwrap python'
alias sbcl='rlwrap sbcl'
alias ev='random-editor'
alias pylio='rlwrap pylio'
alias myros-source='source ~/myros_ws/devel/setup.zsh'
alias jskrbeusgl='rlwrap jskrbeusgl'
alias gosh='rlwrap gosh'
alias android-studio='~/android-studio/bin/studio.sh'

xkbcomp -I$HOME/.xkb ~/.xkb/keymap/mykbd $DISPLAY 2> /dev/null

source /usr/share/gazebo/setup.sh
source $HOME/ros/indigo/devel/setup.zsh
source $HOME/translate.zsh

## SVN and SSH
export SSH_USER="bando"
export SVN_SSH="ssh -l ${SSH_USER}"

export CVSDIR=~/prog
export OPENHRPHOME=$CVSDIR/OpenHRP
export ORGE_RTT_MODE=Copy

#cuda
PATH=$PATH:/usr/local/cuda-8.0/bin:$HOME/blender-2.78-linux-glibc211-x86_64:/usr/lib/nvidia-384/bin
#export LD_LIBRARY_PATH=/usr/local/cuda-8.0/lib64:$LD_LIBRARY_PATH
#export LD_LIBRARY_PATH=/usr/lib/nvidia-384:$LD_LIBRARY_PATH

PATH=$PATH:$HOME/.mybin
PATH=$PATH:~/Android/Sdk/tools:~/Android/Sdk/platform-tools:~/android-studio/bin
export PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(openrave-config --python-dir)/openravepy/_openravepy_
export PYTHONPATH=$PYTHONPATH:$(openrave-config --python-dir):$HOME/workspace/github/pygazebo
export ANDROID_HOME=~/Android/Sdk
export NXPATH=~/workspace/github/PhysX-3.3/PhysXSDK
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$NXPATH/Bin/linux64
#export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export CUDA_PATH=/usr/local/cuda-8.0
export CNOID_INSTALL_DIR=/usr/local/choreonoid
export PATH=${CNOID_INSTALL_DIR}/bin:$PATH
export PATH=$PATH:/home/banmasa/ros/indigo/src/jsk-ros-pkg-unreleased/jsk_rosmake_libs/tvmet/bin
export PYTHONPATH=$PYTHONPATH:/home/banmasa/workspace/github/bullet3/build_cmake/examples/pybullet:/home/banmasa/workspace/github/bullet3/data
export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:/home/banmasa/workspace/hhcc-challenge.git
export PKG_CONFIG_PATH=${CNOID_INSTALL_DIR}/lib/pkgconfig:$PKG_CONFIG_PATH
export QSYS_ROOTDIR="/home/banmasa/intelFPGA/18.1/quartus/sopc_builder/bin"
export PATH=$PATH:$HOME/intelFPGA_lite/18.1/quartus/bin
export PATH=$PATH:$HOME/intelFPGA_lite/18.1/nios2eds/sdk2/bin:/$HOME/intelFPGA_lite/18.1/nios2eds/bin/gnu/H-x86_64-pc-linux-gnu/bin:$HOME/intelFPGA_lite/18.1/nios2eds/bin
export SOPC_KIT_NIOS2=$HOME/intelFPGA_lite/18.1/nios2eds
export QUARTUS_ROOTDIR=$HOME/intelFPGA_lite/18.1/quartus
#export ROBOSCHOOL_PATH=/home/banmasa/workspace/roboschool
## added by Anaconda3 4.4.0 installer
#export PATH="/home/banmasa/anaconda3/bin:$PATH"
## added by Anaconda2 4.4.0 installer
#export PATH="/home/banmasa/anaconda2/bin:$PATH"
