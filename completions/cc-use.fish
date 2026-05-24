# Tab completion for cc-use
# Symlink into fish's completion dir to activate:
#   ln -s ~/.claude/LLMswitch/completions/cc-use.fish ~/.config/fish/completions/cc-use.fish

complete -c cc-use -f -a "(
    for f in ~/.claude/LLMswitch/providers/*.sh
        basename \$f .sh
    end
)"
