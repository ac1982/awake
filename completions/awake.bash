# bash completion for awake. Source it from ~/.bashrc:
#   source /path/to/awake/completions/awake.bash
#
# Written for the bash macOS ships (3.2), so no compopt and no reliance on the
# bash-completion package being installed.

_awake() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]} i

  # Past --, the rest of the line is the user's own command: a command name
  # first, then its arguments, which are most often files.
  for (( i = 1; i < COMP_CWORD; i++ )); do
    [[ ${COMP_WORDS[i]} == -- ]] || continue
    if (( COMP_CWORD == i + 1 )); then
      COMPREPLY=( $(compgen -c -- "$cur") )
    else
      COMPREPLY=( $(compgen -f -- "$cur") )
    fi
    return
  done

  case $prev in
    -h|--help) return ;;    # help exits at once; nothing can follow it
    -w|--wait)
      # Only this user's processes: those are the ones worth waiting on
      COMPREPLY=( $(compgen -W "$(ps -U "$UID" -o pid=)" -- "$cur") )
      return ;;
  esac

  if [[ $cur == -* ]]; then
    COMPREPLY=( $(compgen -W '-b --background -w --wait -h --help --' -- "$cur") )
  elif (( COMP_CWORD == 1 )); then
    # status and off act immediately, so they only make sense first
    COMPREPLY=( $(compgen -W 'status off 30m 1h 2h 4h 8h' -- "$cur") )
  else
    COMPREPLY=( $(compgen -W '30m 1h 2h 4h 8h' -- "$cur") )
  fi
}
complete -F _awake awake
