# fish completion for awake. Link it into fish's completion directory:
#   ln -s /path/to/awake/completions/awake.fish ~/.config/fish/completions/

# Past --, the rest of the line is the user's own command
function __awake_after_dashdash
    contains -- -- (commandline -opc)
end

# awake's own arguments apply until -- hands the line to a command, or until
# --help, which exits at once so nothing can follow it
function __awake_own_args
    set -l tokens (commandline -opc)
    not contains -- -- $tokens; and not contains -- -h $tokens; and not contains -- --help $tokens
end

# Complete everything after -- as if it were typed on its own line
function __awake_complete_command
    set -l tokens (commandline -opc)
    set -l i (contains -i -- -- $tokens)
    set -e tokens[1..$i]
    complete -C (string join -- ' ' (string escape -- $tokens) (commandline -ct))
end

complete -c awake -f
complete -c awake -n __awake_after_dashdash -a '(__awake_complete_command)'

# status and off act immediately, so they only make sense first
complete -c awake -n '__awake_own_args; and test (count (commandline -opc)) -eq 1' \
    -a status -d 'show your caffeinate processes and their elapsed time'
complete -c awake -n '__awake_own_args; and test (count (commandline -opc)) -eq 1' \
    -a off -d 'stop all your caffeinate processes'
complete -c awake -n __awake_own_args -a '30m 1h 2h 4h 8h' -d duration

complete -c awake -n __awake_own_args -s b -l background \
    -d 'run in the background'
complete -c awake -n __awake_own_args -s w -l wait -x -a '(__fish_complete_pids)' \
    -d 'stay awake until this pid exits'
complete -c awake -n __awake_own_args -s h -l help -d 'show help'
